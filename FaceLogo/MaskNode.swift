import UIKit
import SceneKit
import ARKit

class MaskNode: SCNNode {
    
    init(geometry: ARSCNFaceGeometry, image: UIImage? = nil) {
        let material = geometry.firstMaterial
        material?.diffuse.contents = image == nil ? UIColor.blue : image
        material?.lightingModel = .physicallyBased
        super.init()
        self.geometry = geometry
    }
    
    init(geometry: ARSCNFaceGeometry, player: AVPlayer? = nil) {
        let material = geometry.firstMaterial
        material?.diffuse.contents = player == nil ? UIColor.blue : player
        material?.lightingModel = .physicallyBased
        super.init()
        self.geometry = geometry
        player?.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil) { (notification) in
            if let currentItem = notification.object as? AVPlayerItem {
                currentItem.seek(to: .zero, completionHandler: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with anchor: ARFaceAnchor) {
        guard let geometry = geometry as? ARSCNFaceGeometry else {
            return
        }
        geometry.update(from: anchor.geometry)
    }
}
