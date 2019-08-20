import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var alphaSlider: UISlider!
    @IBOutlet var capturedImageView: UIImageView! {
        didSet {
            
            capturedImageObserve = capturedImageView.observe(\UIImageView.image) { (_, change) in
                if change.newValue == nil {                    self.capturedImageView.gestureRecognizers?.forEach({self.capturedImageView.removeGestureRecognizer($0)})
                    return
                } else {
                    let saveGesture = UITapGestureRecognizer(target: self, action: #selector(self.saveImage))
                    self.capturedImageView.addGestureRecognizer(saveGesture)
                }
            }
        }
    }
    @IBOutlet var stateLabel: UILabel!
    
    var player: AVPlayer?
    
    var capturedImageObserve: NSKeyValueObservation?
    
    var virtualFaceNode: MaskNode? {
        didSet {
            setupFaceNodeContent()
        }
    }
    
    private var pickerController: UIImagePickerController?
    private var faceNode: SCNNode?
    private let serialQueue = DispatchQueue(label: "com.face-logo.serial-queue")
    
    private func setupFaceNodeContent() {
        guard let faceNode = faceNode else { return }
        
        for child in faceNode.childNodes {
            child.removeFromParentNode()
        }
        
        if let content = virtualFaceNode {
            faceNode.addChildNode(content)
        }
    }
    
    // マスクを作成
    private func createFaceNode(image: UIImage?) -> MaskNode? {
        
        guard let device = MTLCreateSystemDefaultDevice(),
            let geometry = ARSCNFaceGeometry(device: device) else { return nil }
        let node = MaskNode(geometry: geometry, image: image)
        node.opacity = 1 - CGFloat(alphaSlider.value)
        return node
    }
    
    private func createFaceNode(player: AVPlayer?) -> MaskNode? {
        
        guard let device = MTLCreateSystemDefaultDevice(),
            let geometry = ARSCNFaceGeometry(device: device) else { return nil }
        let node = MaskNode(geometry: geometry, player: player)
        node.opacity = 1 - CGFloat(alphaSlider.value)
        return node
    }
    
    @objc private func showImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        pickerController = UIImagePickerController()
        pickerController?.delegate = self
        pickerController?.sourceType = .photoLibrary
        pickerController?.mediaTypes = ["public.movie", "public.image"]
        present(pickerController!, animated: true, completion: nil)
    }
    
    @objc private func saveImage() {
        guard let image = capturedImageView.image else { return }
        let alert = UIAlertController(title: "写真を保存しますか？", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { (_) in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.savedToAlbum(_:didFinishSavingWithError:contextInfo:)), nil)
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: .default, handler: nil))
        present(alert, animated: true) {
            self.capturedImageView.isHidden = true
            self.capturedImageView.image = nil
        }
    }
    
    @objc private func savedToAlbum(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        stateLabel.isHidden = false
        if error != nil {
            stateLabel.text = "エラー発生。。。写真を保存できませんでした。"
            return
        }
        stateLabel.text = "写真を保存したよ！"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stateLabel.isHidden = true
        }
    }
    
    @objc private func showCapturedImage() {
//        guard let currentFrame = sceneView.session.currentFrame else { return }
//        let capturedImage = currentFrame.capturedImage
//        let ciImage = CIImage(cvImageBuffer: capturedImage)
//        let image = UIImage(ciImage: ciImage)
//        capturedImageView.image = image
//        capturedImageView.isHidden = false
        
        capturedImageView.image = sceneView.snapshot()
        capturedImageView.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // シーンの照明を更新するかどうか
        sceneView.automaticallyUpdatesLighting = true
        
        virtualFaceNode = createFaceNode(image: nil)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(showImagePickerController))
        swipeGesture.direction = .up
        sceneView.addGestureRecognizer(swipeGesture)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(showCapturedImage))
        longTapGesture.minimumPressDuration = 1.5
        sceneView.addGestureRecognizer(longTapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    deinit {
        capturedImageObserve?.invalidate()
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let opacity = 1 - CGFloat(sender.value)
        virtualFaceNode?.opacity = opacity
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    // 新しいARAnchorが追加された時に呼ばれる。
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        faceNode = node
        serialQueue.async {
            self.setupFaceNodeContent()
        }
    }
    
    
    
    // ARAnchorが更新された時に呼ばれる。
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARFaceAnchor else {
            return
        }
        virtualFaceNode?.update(with: anchor)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        DispatchQueue.main.async {
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let originalImage = info[.originalImage] as? UIImage {
            dismiss(animated: true) {
                self.virtualFaceNode = self.createFaceNode(image: originalImage)
            }
        } else if let originalMovieURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            let avPlayer = AVPlayer(url: originalMovieURL)
            player = avPlayer
            dismiss(animated: true) {
                self.virtualFaceNode = self.createFaceNode(player: avPlayer)
            }
        }
    }
}
