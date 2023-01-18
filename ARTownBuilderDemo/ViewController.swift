/**************************************************************************
* Copyright (C) echo3D, Inc. 2018-2023.
* echo3D, Inc. proprietary and confidential.
* Use subject to the terms of the Terms of Service available at
* https://www.echo3d.com/terms, or another agreement
* between echo3D, Inc. and you, your company or other organization.
**************************************************************************/

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    var e:echo3D!;
    
    //variables to store data for horizontal planes
    var planeColor: UIColor?
    var planeColorOff: UIColor?
    var myPlaneNode: SCNNode?
    var myPlanes: [SCNNode] = []
    
    //echo3D entry id's for 3D models for app
    let treeId = "a3afa700-c20a-4366-9441-64ea0a14f750"// insert your entry id here
    let picnicTableId = "ddb22b24-1acc-41a6-825d-fb2d78040f9c" // insert your entry id here
    let roadId = "32b22856-24af-43c4-bbbe-88ad98998a46" // insert your entry id here
    let poolId = "0916c8f6-5d31-4b66-9bf4-a5b1f4e6509f" // insert your entry id here
    let mailBoxId = "3952a84c-0b6a-4917-9e89-89bc7c318590" // insert your entry id here
    let houseId = "a294665c-7e9c-4d15-96de-fb750afded31" // insert your entry id here
    let deerId = "d356f8f6-1f60-4613-a108-80eb50ae3ded" // insert your entry id here
    let bikeId = "5c76694e-ec84-411e-b85c-670439717932" // insert your entry id here

    //buttons for selecting objects to add to sceneView
    @IBOutlet weak var togglePlaneButton: UIButton!
    
    @IBOutlet weak var treeButton: UIButton!
    
    @IBOutlet weak var roadButton: UIButton!
    
    @IBOutlet weak var poolButton: UIButton!
    
    @IBOutlet weak var ballParkButton: UIButton!
    
    @IBOutlet weak var mailBoxButton: UIButton!
    
    @IBOutlet weak var houseButton: UIButton!
    
    @IBOutlet weak var deerButton: UIButton!
    
    //buttons for editing nodes in scene
    @IBOutlet weak var dragButton: UIButton!
    
    @IBOutlet weak var rotateButton: UIButton!

    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var addButton: UIButton!

    @IBOutlet weak var bikeButton: UIButton!
    
    //variables for keeping track of pan gesture state
    var panStartZ: CGFloat?
    var draggingNode: SCNNode?
    var lastPanLocation: SCNVector3?
    
    //selected index and id, for the object a user has selected
    //using choice buttons
    var selectedId: String?
    var selectedInd = 0
    
    //array of the echo3D entry id's of 3D models
    var idArr: [String]?
    
    //constants to scale down the nodes, when first added to sceneView
    var scaleConstants: [CGFloat]?


    override func viewDidLoad() {
        super.viewDidLoad()

        //set all model choice button alpha's to the deselect state
        resetChoiceButtonAlphas()
        
        //select the treeId, by making it's entyr id the selected id
        //and by updating it's button alpha to the selected state
        selectedId = treeId
        treeButton.alpha = 1.0
        
        //set all edit button alpha's to the deselect state
        resetEditButtonAlphas()
        //set the add button alpha to the selected state
        addButton.alpha = 1.0
        
        //array of all entry id's of models users can add
        idArr = [treeId, roadId, poolId, picnicTableId, mailBoxId, houseId, deerId, bikeId]
        
        //default scale constants for the objects (reducing their size to start)
        //(if you chose entries different from the suggested,
        //update these constants to match the size of the entries chosen)
        scaleConstants = [0.009, 0.0004, 0.002, 0.0001, 0.004, 0.003, 0.0004, 0.000013]

        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true

        e = echo3D();
        
        //choose a color to use for the plane
        planeColor = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.6))
        planeColorOff = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.0))


        //create and add a recognizer to respond to taps on the scene view
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addObjToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //create and add a recognizer to respond to finger pans on the scene view
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        sceneView.addGestureRecognizer(panRecognizer)
        
        //create and add a recognizer to respond to finger pinchs on the scene view
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRecognizer:)))
        sceneView.addGestureRecognizer(pinchRecognizer)

        //set scene view to automatically add omni directional light when needed
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //configure scene view session to detect horizontal planes
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
       
        sceneView.delegate = self
        
        //uncomment to see feature points
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //when the view appears, present an alert to the user
        //letting them know to scan a horizontal surface
        let alert = UIAlertController(title: "Scan And Get Started", message: "Move your phone around to scan a horizontal plane", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    

    //handlePinch(panGesture:) - takes a UIPinchGestureRecognizer as an argument
    //called whenever a user does a two finger pinch
    //calls the doScale method
    @objc func handlePinch(pinchRecognizer: UIPinchGestureRecognizer){
        //call do scale to scale node on user pinch gesture
        doScale(recognizer: pinchRecognizer)
    }
    
    //addObjToScene(panGesture:) - takes a UIGestureRecognizer as an argument
    //called whenever a user taps the screen
    //calls either doAdd() or doDelete()
    @objc func addObjToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer){
        //get location of the tap gesture
        let tapLocation = recognizer.location(in: sceneView)

        //if delete is selected
        if self.deleteButton.alpha == 1 {
            //use hit test to get the node tapped
            guard let hitNodeResult = sceneView.hitTest(tapLocation, options: nil).first else {return}
            
            //if the node is a plain node return
            if(hitNodeResult.node.name == "plain"){
               return
            }
            
            //delete tapped node
            hitNodeResult.node.removeFromParentNode()
        }
        else if self.addButton.alpha == 1 {
            //if add selected, add a new node
            doAdd(withGestureRecognizer: recognizer)
        }
    }
    
    //handelePan(panGesture:) - takes a UIPanGestureRecognizer as an argument
    //called whenever a user makes a pan gesture
    //calls either doDrag() or doRotate()
    @objc func handlePan(panGesture: UIPanGestureRecognizer){
        //if drag button is selected drag the touched node on pan gesture
        /// but if rotate is selected rotate the node
        if self.dragButton.alpha == 1 {
            doDrag(panGesture: panGesture)
        }
        else if self.rotateButton.alpha == 1{
            doRotate(rotateGesture: panGesture)
        }
    }
    
    //doScale(recognizer:) - takes a UIPinchGestureRecognizer as an argument
    //scales a node to the sceneView based on the state of the gesture recognizer
    func doScale(recognizer: UIPinchGestureRecognizer){
        //get the location of the pinch
        let location = recognizer.location(in: sceneView)
        
        //get the node touched by pinch
        guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else {return}
        if(isPlane(node: hitNodeResult.node)){
            return
        }
        //if the pinch has begun, or continues
        if recognizer.state == .began || recognizer.state == .changed {
            //scale the touched node
            let action = SCNAction.scale(by: recognizer.scale, duration: 0.3)
            hitNodeResult.node.runAction(action)
            recognizer.scale = 1.0
        }
    }
    
    //doAdd(recognizer:) - takes a UIGestureRecognizer as an argument
    //adds a node to the sceneView based on the state of the gesture recognizer
    func doAdd(withGestureRecognizer recognizer: UIGestureRecognizer){
        //get the location of the tap
        let tapLocation = recognizer.location(in: sceneView)

        
        //a hit test to see if the user has tapped on an existing plane
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        //make sure a result of the hit test exists
        guard let hitTestResult = hitTestResults.first else { return }
        
        //get the translation, or where we will be adding our node
        let translation = SCNVector3Make(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
       //load scene (3d model) from echo3D using the entry id of the users selected button
        e.loadSceneFromEntryID(entryID: idArr![selectedInd]) { (selectedScene) in
            //make sure the scene has a scene node
            guard let selectedNode = selectedScene.rootNode.childNodes.first else {return}
            
            //set the position of the node
            selectedNode.position = SCNVector3(x,y,z)
            
            //scale down the node using our scale constants
            let action = SCNAction.scale(by: scaleConstants![selectedInd], duration: 0.3)
            selectedNode.runAction(action)
            
            //set the name of the node (just in case we ever need it)
            selectedNode.name = idArr![selectedInd]
            
            //add the node to our scene
            sceneView.scene.rootNode.addChildNode(selectedNode)
        }
    }
    
    //doDrag(panGesture:): takes a UIPanGesture as an argument
    //moves the location of a node based on the state of the pan gesture
    func doDrag(panGesture: UIPanGestureRecognizer){
        guard let view = self.sceneView else {return}
        //get the location of the user's pan gesture
        let location = panGesture.location(in: self.view)
        print("begin pan")

        switch panGesture.state {
        //if the pan gesture is just beginning
        case .began:
            //do a hit test, to see if the user has touched a node
            guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else {return}
            //if the user touched a horizontal plane, make no edits
            if(isPlane(node: hitNodeResult.node)){
                return
            }
            //save the pan location, the z position of the node (which will stay constant during drag)
            //and the node being dragged
            lastPanLocation = hitNodeResult.worldCoordinates
            
            //project a point from the 3D world of the renderer to the 2D pixel coordinate system
            //getting the z coordinate of the dragging node
            panStartZ = CGFloat(view.projectPoint(lastPanLocation!).z)
            
            draggingNode = hitNodeResult.node
        case .changed:
            guard lastPanLocation != nil, draggingNode != nil, panStartZ != nil else {return}
            //get the current postion of the user's pan gesture
            let location = panGesture.location(in: view)
            
            //get a 3D position, from the 2D pixel coordinate system
            let worldTouchPosition = view.unprojectPoint(SCNVector3(location.x, location.y, panStartZ!))
            
            //update the node being dragged
            draggingNode?.worldPosition = worldTouchPosition
        case .ended:
            lastPanLocation = nil
            draggingNode = nil
            panStartZ = nil
        default:
            break
        }
    }
    
    //doRotate(rotateGesture:): takes a UIPanGesture as an argument
    //rotate's a node based on the state of the pan gesture
    func doRotate(rotateGesture: UIPanGestureRecognizer){
        guard let view = self.sceneView else {return}
        //get location of the user's rotate gesture
        let location = rotateGesture.location(in: self.view)
        
        if rotateGesture.state == .began || rotateGesture.state == .changed {
            //check if the location of the rotate gesture hits a node
            guard let hitNodeResult = view.hitTest(location, options: nil).first else {return}
            //if the node hit is a plane return
            if(isPlane(node: hitNodeResult.node)){
                return
            }
            //rotate node it's y direction
            //this is a one directional rotate
            hitNodeResult.node.runAction(SCNAction.rotateBy(x: 0.0, y: 0.08, z: 0.0, duration: 0.5))
        }
    }
    

    //resetChoiceButtonAlphas()
    //sets all choice button alphas to the default state
    func resetChoiceButtonAlphas(){
        //when buttons are not selected, dim them
        treeButton.alpha = 0.3
        roadButton.alpha = 0.3
        poolButton.alpha = 0.3
        ballParkButton.alpha = 0.3
        mailBoxButton.alpha = 0.3
        houseButton.alpha = 0.3
        deerButton.alpha = 0.3
        bikeButton.alpha = 0.3
    }
    
    //resetEditButtonAlphas()
    //sets all edit button alphas to the default state
    func resetEditButtonAlphas(){
        //when buttons are not selected, dim them
        dragButton.alpha = 0.3
        rotateButton.alpha = 0.3
        deleteButton.alpha = 0.3
        addButton.alpha = 0.3
}

    //choiceButtonTapped(sender:)
    //takes a sender as an argument
    //for our purposes the sender represents which choice button that was tapped
    //updates state of buttons, by updating alphas
    @IBAction func choiceButtonTapped(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        //reset all choice buttons (dimming them)
        resetChoiceButtonAlphas()
        
        //set the user's selected button to the selected state (not dimmed)
        button.alpha = 1.0
        selectedInd = button.tag
    }
    
    //editButtonTapped(sender:): takes a sender as an argument
    //called whenever an edit button is tapped
    //for our purposes the sender represents which edit button that was tapped
    //updates state of buttons, by updating alphas
    @IBAction func editButtonTapped(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        //reset edit all buttons (dimming them)
        resetEditButtonAlphas()
        
        //set the user's selected button to the selected state (not dimmed)
        button.alpha = 1.0
    }
    
    //togglePlaneTapped(sender:):
    //called whenever the togglePlaneButton is tapped
    //changes the state of the togglePlaneButton (by changing its alpha)
    //calls the togglePlane(planeNode:) function on all planeNodes
    @IBAction func togglePlaneTapped(_ sender: Any) {
        //if toggle plane tapped,
        //iterate through all horizontal planes, and set their alpha's to 0.0
        for plane in myPlanes {
               togglePlane(planeNode: plane)
        }
        
        //change the state of the toggle plane button (dim or undimmed)
        togglePlaneButton.alpha = togglePlaneButton.alpha < 0.5 ? 1.0 : 0.3
        print(togglePlaneButton.alpha)
    }
    
    //togglePlane(planeNode:): takes a SCNNode as an argument
    //depending on the state of the togglePlaneButton, changes the color
    //of planeNode. (either to fully transparent, or to a translucent green)
    func togglePlane(planeNode: SCNNode){
        //make plane visible or invisible, by changing its color
        if togglePlaneButton.alpha.isEqual(to: 1.0) {
           planeNode.geometry?.materials.first?.diffuse.contents = planeColorOff
        }
        else {
            planeNode.geometry?.materials.first?.diffuse.contents = planeColor
        }
    }
    
    //isPlane(node:): takes an SCNNode as an argument
    //returns true if the node is named "plain" otherwise returns false
    func isPlane(node: SCNNode) -> Bool {
        guard  let name = node.name else {
            return false
        }
        if name == "plain"{
            return true
        }
        return false
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else {return}
        
        //update the plane node, as plane anchor information updates
        
        //get the width and the height of the planeAnchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)
        
        //set the plane to the new width and height
        plane.width = w
        plane.height = h

        //get the x y and z position of the plane anchor
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        //set the nodes position to the new x,y, z location
        planeNode.position = SCNVector3(x, y, z)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        //add a plane node to the scene
        
        //get the width and height of the plane anchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)
        
        //create a new plane
        let plane = SCNPlane(width: w, height: h)
       
        //set the color of the plane
        plane.materials.first?.diffuse.contents = planeColor!
        
        //create a plane node from the scene plane
        let planeNode = SCNNode(geometry: plane)
        
        //get the x, y, and z locations of the plane anchor
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        //set the plane position to the x,y,z postion
        planeNode.position = SCNVector3(x,y,z)
        
        //turn th plane node so it lies flat horizontally, rather than stands up vertically
        planeNode.eulerAngles.x = -.pi / 2
        
        //set the name of the plane
        planeNode.name = "plain"
        
        //save the plane (used to later toggle the transparency of th plane)
        myPlaneNode = planeNode
        myPlanes.append(planeNode)
        
        //add plane to scene
        node.addChildNode(planeNode)
    }
    
}

//Additional notes and credits:
//Apple Documentation, Tracking and Visual Planes - https://developer.apple.com/documentation/arkit/world_tracking/tracking_and_visualizing_planes
//Jayven Nhan, ArKit Horizontal Planes- https://www.appcoda.com/arkit-horizontal-plane/
//Sri Adatrao, ARkit detecting planes - https://machinethinks.com/arkit-detecting-planes-and-placing-objects/
//Benjamin Kindle, Dragging Objects in SceneKit and ARKit  - https://medium.com/@literalpie/dragging-objects-in-scenekit-and-arkit-3568212a90e5

