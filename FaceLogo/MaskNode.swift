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
