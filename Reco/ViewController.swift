//
//  ViewController.swift
//  Reco
//
//  Created by PT. GO-JEK INDONESIA on 26/07/18.
//  Copyright © 2018 Reco. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

import RxSwift
import RxCocoa
import PKHUD
import AWSRekognition
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var 👜 = DisposeBag()
    var faces: [Face] = []
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    let rekognitionClient = AWSRekognition.default()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        bounds = sceneView.bounds
        
        // Create a new scene //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        // Set the scene to the view //sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        Observable<Int>.interval(0.6, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .concatMap{ _ in  self.faceObservation() }
            .flatMap{ Observable.from($0)}
            .flatMap{ self.faceClassification(face: $0.observation, image: $0.image, frame: $0.frame) }
            .subscribe { [unowned self] event in
                guard let element = event.element else {
                    print("No element available")
                    return
                }
                self.updateNode(classes: element.classes, position: element.position, frame: element.frame)
            }.disposed(by: 👜)
        
        
        Observable<Int>.interval(0.6, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .subscribe { [unowned self] _ in
                
                self.faces.filter{ $0.updated.isAfter(seconds: 1.5) && !$0.hidden }.forEach{ face in
                    print("Hide node: \(face.name)")
                    DispatchQueue.main.async { face.node.hide() }
                }
            }.disposed(by: 👜)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .limited(.initializing):
            PKHUD.sharedHUD.contentView = PKHUDProgressView(title: "Initializing", subtitle: nil)
            PKHUD.sharedHUD.show()
        case .notAvailable:
            print("Not available")
        default:
            PKHUD.sharedHUD.hide()
        }
    }
    /////////////////////////////////////////////////Add Face to Collection/////////////////////////////////////////

    private func indexFace(_ image: CIImage){
        let indexReq = AWSRekognitionIndexFacesRequest() //
        indexReq?.collectionId = ""  // Edit with Face Collection ID
        indexReq?.externalImageId = "" // Fill with user id
        
        let AWSimage = AWSRekognitionImage()
        AWSimage?.bytes = UIImageJPEGRepresentation(UIImage(ciImage: image), 0.7)
        indexReq?.image = AWSimage
        AWSRekognition.default().indexFaces(indexReq!) { (response, error) in
            if error == nil {
                print("Error occured")
            }
            else{
                // success in indexing face, and process success result
                
            }
        }
    }
    
    //////////////////////////////////////////////////////Face Detection/////////////////////////////////////////
    
    private func faceObservation() -> Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]> {
        return Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]>.create{ observer in
            guard let frame = self.sceneView.session.currentFrame else {
                print("No frame available")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Verify tracking state and abort
            //            guard case .normal = frame.camera.trackingState else {
            //                print("Tracking not available: \(frame.camera.trackingState)")
            //                observer.onCompleted()
            //                return Disposables.create()
            //            }
            
            // Create and rotate image
            let image = CIImage.init(cvPixelBuffer: frame.capturedImage).rotate
            
            let facesRequest = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil else {
                    print("Face request error: \(error!.localizedDescription)")
                    observer.onCompleted()
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    print("No face observations")
                    observer.onCompleted()
                    return
                }
                
                // Map response
                let response = observations.map({ (face) -> (observation: VNFaceObservation, image: CIImage, frame: ARFrame) in
                    return (observation: face, image: image, frame: frame)
                })
                observer.onNext(response)
                observer.onCompleted()
                
            }
            try? VNImageRequestHandler(ciImage: image).perform([facesRequest])
            
            return Disposables.create()
        }
    }
    /////////////////////////////////////////////////Face Classification/////////////////////////////////////////

    private func faceClassification(face: VNFaceObservation, image: CIImage, frame: ARFrame) -> Observable<(classes: AWSRekognitionRecognizeCelebritiesResponse, position: SCNVector3, frame: ARFrame)> {
        return Observable<(classes: AWSRekognitionRecognizeCelebritiesResponse, position: SCNVector3, frame: ARFrame)>.create{ observer in
            
            // Determine position of the face
            let boundingBox = self.transformBoundingBox(face.boundingBox)
            guard let worldCoord = self.normalizeWorldCoord(boundingBox) else {
                print("No feature point found")
                observer.onCompleted()
                return Disposables.create()
            }
            guard let getCelebrityRequest =  AWSRekognitionRecognizeCelebritiesRequest() else {
                puts("Unable to initialize AWSRekognitionRecognizeCelebritiesRequest.")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Create Classification request
            let pixel = image.cropImage(toFace: face)
            //convert the cropped image to UI image
            let uiImage: UIImage = self.convert(cmage: pixel)
            
            let AWSimage = AWSRekognitionImage()
            AWSimage!.bytes = UIImageJPEGRepresentation(uiImage, 0.7)
            getCelebrityRequest.image = AWSimage
            self.rekognitionClient.recognizeCelebrities(getCelebrityRequest) { (response:AWSRekognitionRecognizeCelebritiesResponse?, error:Error?) in
                if error == nil
                {   // success
                    print(response!)
                    // generate a new type of response
                    
                    observer.onNext((classes: response!, position: worldCoord, frame: frame))
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }
    
    private func updateNode(classes: AWSRekognitionRecognizeCelebritiesResponse, position: SCNVector3, frame: ARFrame) {
        
        let person = classes.celebrityFaces![0]
        
        let name = person.name
        
        //check if there is recognized person
        
        //if there is recognized person
        print("""
            FIRST
            confidence: \(String(describing: person.face?.confidence)) for \(String(describing: person.name))
            """)
        if Double(truncating: (person.face?.confidence!)!) < 0.80 {
            print("not so sure")
            return
        }
        
        // Filter for existent face
        let results = self.faces.filter{ $0.name == name && $0.timestamp != frame.timestamp }
            .sorted{ $0.node.position.distance(toVector: position) < $1.node.position.distance(toVector: position) }
        
        // Create new face
        guard let existentFace = results.first else {
            let node = SCNNode.init(withText: name!, position: position)
            
            DispatchQueue.main.async {
                self.sceneView.scene.rootNode.addChildNode(node)
                node.show()
                
            }
            let face = Face.init(name: name!, node: node, timestamp: frame.timestamp)
            self.faces.append(face)
            return
        }
        
        // Update existent face
        DispatchQueue.main.async {
            
            // Filter for face that's already displayed
            if let displayFace = results.filter({ !$0.hidden }).first  {
                
                let distance = displayFace.node.position.distance(toVector: position)
                if(distance >= 0.03 ) {
                    displayFace.node.move(position)
                }
                displayFace.timestamp = frame.timestamp
                
            } else {
                existentFace.node.position = position
                existentFace.node.show()
                existentFace.timestamp = frame.timestamp
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        👜 = DisposeBag()
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    /////////////////////////////////////////////////////////////////////////// MARK: - ARSCNViewDelegate
    
    /// In order to get stable vectors, we determine multiple coordinates within an interval.
    ///
    /// - Parameters:
    ///   - boundingBox: Rect of the face on the screen
    /// - Returns: the normalized vector
    private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        Array(0...2).forEach{_ in
            if let position = determineWorldCoord(boundingBox) {
                array.append(position)
            }
            usleep(12000) // .012 seconds
        }
        
        if array.isEmpty {
            return nil
        }
        
        return SCNVector3.center(array)
    }
    
    
    /// Determine the vector from the position on the screen.
    ///
    /// - Parameter boundingBox: Rect of the face on the screen
    /// - Returns: the vector in the sceneView
    private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
        
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
            //            print("vector distance: \(closestResult.distance)")
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }
    
    
    /// Transform bounding box according to device orientation
    ///
    /// - Parameter boundingBox: of the face
    /// - Returns: transformed bounding box
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        var size: CGSize
        var origin: CGPoint
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            size = CGSize(width: boundingBox.width * bounds.height,
                          height: boundingBox.height * bounds.width)
        default:
            size = CGSize(width: boundingBox.width * bounds.width,
                          height: boundingBox.height * bounds.height)
        }
        
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            origin = CGPoint(x: boundingBox.minY * bounds.width,
                             y: boundingBox.minX * bounds.height)
        case .landscapeRight:
            origin = CGPoint(x: (1 - boundingBox.maxY) * bounds.width,
                             y: (1 - boundingBox.maxX) * bounds.height)
        case .portraitUpsideDown:
            origin = CGPoint(x: (1 - boundingBox.maxX) * bounds.width,
                             y: boundingBox.minY * bounds.height)
        default:
            origin = CGPoint(x: boundingBox.minX * bounds.width,
                             y: (1 - boundingBox.maxY) * bounds.height)
        }
        
        return CGRect(origin: origin, size: size)
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
