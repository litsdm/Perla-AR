//
//  ViewController.swift
//  Perla-AR
//
//  Created by Carlos Diez on 8/19/19.
//  Copyright © 2019 Carlos Diez. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    private var imageConfiguration: ARImageTrackingConfiguration?
    private var worldConfiguration: ARWorldTrackingConfiguration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        // sceneView.showsStatistics = true
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        instructionLabel.layer.cornerRadius = 6
        
        setupObjectDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let configuration = worldConfiguration {
            sceneView.debugOptions = .showFeaturePoints
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func setupObjectDetection() {
        worldConfiguration = ARWorldTrackingConfiguration()
        
        guard let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Images", bundle: nil) else {
                fatalError("Missing expected asset catalog resources.")
        }
        worldConfiguration?.detectionImages = referenceImages
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async { self.instructionLabel.isHidden = true }
        if let imageAnchor = anchor as? ARImageAnchor {
            handleFoundImage(imageAnchor, node)
        }
    }
    
    private func handleFoundImage(_ imageAnchor: ARImageAnchor, _ node: SCNNode) {
        let name = imageAnchor.referenceImage.name!
        print("you found a \(name) image")
        let machineNode = create3DModelNode(position: SCNVector3(x: imageAnchor.transform.columns.3.x,
        y: imageAnchor.transform.columns.3.y,
        z: imageAnchor.transform.columns.3.z))
        sceneView.scene.rootNode.addChildNode(machineNode)
        // node.addChildNode(shipNode)
    }
    
    private func create3DModelNode(position: SCNVector3) -> SCNNode {
        let node = SCNNode()
        let scene = SCNScene(named: "art.scnassets/perla_machine.dae")
        let nodeArray = scene!.rootNode.childNodes
        for childNode in nodeArray {
            node.addChildNode(childNode as SCNNode)
        }
        node.position = position
        node.scale = SCNVector3Make(0.05, 0.05, 0.05)
        return node
    }

    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        guard
            let error = error as? ARError,
            let code = ARError.Code(rawValue: error.errorCode)
            else { return }
        instructionLabel.isHidden = false
        switch code {
        case .cameraUnauthorized:
            instructionLabel.text = "Camera tracking is not available. Please check your camera permissions."
        default:
            instructionLabel.text = "Error starting ARKit. Please fix the app and relaunch."
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(let reason):
            instructionLabel.isHidden = false
            switch reason {
            case .excessiveMotion:
                instructionLabel.text = "Too much motion! Slow down."
            case .initializing, .relocalizing:
                instructionLabel.text = "ARKit is doing it's thing. Move around slowly for a bit while it warms up."
            case .insufficientFeatures:
                instructionLabel.text = "Not enough features detected, try moving around a bit more or turning on the lights."
            }
        case .normal:
            instructionLabel.text = "Point the camera at a match box."
        case .notAvailable:
            instructionLabel.isHidden = false
            instructionLabel.text = "Camera tracking is not available."
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
