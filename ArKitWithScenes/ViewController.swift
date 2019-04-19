//
//  ViewController.swift
//  ArKitWithScenes
//
//  Created by Mompi on 10/04/19.
//  Copyright © 2019 mompi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MBProgressHUD

class ViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource,UICollectionViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    var furnitures = ["Furniture1","Furniture2","Furniture3","Furniture4"]
    var scenesNames = ["sofaBlack","sofaGrey","table","drawerWithLight"]
    var globalNode = [SCNNode]()
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        furnitureSetup()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addfurnitureNode))
        sceneView.addGestureRecognizer(tapGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomfurnitureNode))
        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return furnitures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! HorizontalCollectionViewCell
        cell.furnitureImage.image = UIImage(named: furnitures[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //Anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0)
        //Adding node of plane
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2//
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeNode = node.childNodes.first
        guard let plane = planeNode!.geometry as? SCNPlane else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)  
        let z = CGFloat(planeAnchor.center.z)
        planeNode!.position = SCNVector3(x, y, z)
    }
    
    func getParentNode(anchor: ARPlaneAnchor, index: Int) ->SCNNode{
        
        globalNode[index].geometry?.firstMaterial?.isDoubleSided = true
        globalNode[index].position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
        globalNode[index].scale = SCNVector3(0.2, 0.2, 0.2)
        return globalNode[index]
    }
    
    fileprivate func furnitureSetup() {
        for i in 0...furnitures.count-1{
            let node = SCNNode()
            node.name = scenesNames[i]
            let scene = SCNScene(named: "art.scnassets/\(String(describing: scenesNames[i])).scn")!
            let nodeArray = scene.rootNode.childNodes
            for childNode in nodeArray {
                node.addChildNode(childNode as SCNNode)
            }
            node.scale = SCNVector3(0.1, 0.1, 0.1)
            globalNode.append(node)
        }
    }
    
    fileprivate func addNode(_ position: SCNVector3) {
        sceneView.scene.rootNode.enumerateChildNodes {(node, _) in
            if node.name == scenesNames[selectedIndex]
            {
                node.removeFromParentNode()
            }
        }
        
        globalNode[selectedIndex].geometry?.firstMaterial?.isDoubleSided = true
        globalNode[selectedIndex].position = position
        sceneView.scene.rootNode.addChildNode(globalNode[selectedIndex])
    }
    
    fileprivate func showToast(message:String) {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .text
        hud.label.text = message
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10.0;
        hud.offset.y = 150.0;
        hud.hide(animated: true, afterDelay: 3)
    }
    
    @objc func addfurnitureNode(sender:UITapGestureRecognizer){
        let tapLocation = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlane)
        guard let hitTestResult = hitTestResults.first else {
            showToast(message: "Plane not detected")
            return
        }
        
//        sceneView.scene.rootNode.enumerateChildNodes {(node, _) in
////            if node.name == scenesNames[selectedIndex]
////            {
//                node.removeFromParentNode()
////            }
//        }
        let position = SCNVector3(CGFloat(hitTestResult.worldTransform.columns.3.x), CGFloat(hitTestResult.worldTransform.columns.3.y), CGFloat(hitTestResult.worldTransform.columns.3.z))
        addNode(position)
        
        
    }
    @objc func zoomfurnitureNode(sender:UIPinchGestureRecognizer){
        let nodeToScale = globalNode[selectedIndex] 
        if sender.state == .changed {
            
            let pinchScaleX: CGFloat = sender.scale * CGFloat((nodeToScale.scale.x))
            let pinchScaleY: CGFloat = sender.scale * CGFloat((nodeToScale.scale.y))
            let pinchScaleZ: CGFloat = sender.scale * CGFloat((nodeToScale.scale.z))
            nodeToScale.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            sender.scale = 1
            
        }
        if sender.state == .ended { }
    }
}
