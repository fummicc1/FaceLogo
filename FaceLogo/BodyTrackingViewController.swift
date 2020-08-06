//
//  BodyTrackingViewController.swift
//  FaceLogo
//
//  Created by Fumiya Tanaka on 2020/08/06.
//  Copyright © 2020 Fumiya Tanaka. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class BodyTrackingViewController: UIViewController {

    @IBOutlet private weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
    }
}

extension BodyTrackingViewController: ARSCNViewDelegate {
    
}
