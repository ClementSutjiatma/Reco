/**
 
 Copyright 2017 IBM Corp. All Rights Reserved.
 Licensed under the Apache License, Version 2.0 (the 'License'); you may not
 use this file except in compliance with the License. You may obtain a copy of
 the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an 'AS IS' BASIS, WITHOUT
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 License for the specific language governing permissions and limitations under
 the License.
 */
 
import Foundation
import ARKit
import SwiftyJSON

public extension SCNNode {
    convenience init(withFullName name: String, position: SCNVector3) {
        let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // Full Name text
        let fullName = name
        let fullNameBubble = SCNText(string: fullName, extrusionDepth: CGFloat(bubbleDepth))
        fullNameBubble.font = UIFont(name: "Avenir", size: 1)?.withTraits(traits: .traitBold)
        fullNameBubble.alignmentMode = kCAAlignmentCenter
        fullNameBubble.firstMaterial?.diffuse.contents = UIColor.black
        fullNameBubble.firstMaterial?.specular.contents = UIColor.white
        fullNameBubble.firstMaterial?.isDoubleSided = true
        fullNameBubble.chamferRadius = CGFloat(bubbleDepth)
        // fullname BUBBLE NODE
        let (minBound, maxBound) = fullNameBubble.boundingBox
        let fullNameNode = SCNNode(geometry: fullNameBubble)
        // Centre Node - to Centre-Bottom point
        fullNameNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        fullNameNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        fullNameNode.simdPosition = simd_float3.init(x: 0.06, y: 0.09, z: 0)
        self.init()
        addChildNode(fullNameNode)
        constraints = [billboardConstraint]
        self.position = position
    }
    
    // returns the height of the plane
    func addTwitter(username: NSString, timestamp: NSString, retweets: NSString, replies: NSString, likes: NSString, text: NSString, billboard_position: simd_float3) -> Float{
        let username_size: Float = 0.02
        let padding: Float = 0.01
        let spacing: Float = 0.01
        var lines = 0
        var tweet_text: String = text as String
        
        (lines, tweet_text) = tweet_text.inserting(separator: "\n", every: 42)
        
        // Display username
        let usernameGeometry = SCNText(string: "/" + (username as String), extrusionDepth: 1.0)
        usernameGeometry.font = UIFont(name: "Arial", size: 1)
        usernameGeometry.firstMaterial!.diffuse.contents = UIColor(rgb: 0x00aced)
        let usernameNode = SCNNode(geometry: usernameGeometry)
        
        // Update object's pivot to its center
        // https://stackoverflow.com/questions/44828764/arkit-placing-an-scntext-at-a-particular-point-in-front-of-the-camera
        var (min, max) = usernameGeometry.boundingBox
        usernameNode.pivot = SCNMatrix4MakeTranslation(min.x , min.y + 0.5 * (max.y - min.y), min.z + 0.5 * (max.z - min.z))
        usernameNode.scale = SCNVector3(0.01, 0.01, 0.01)
        
        // Display tweet text
        let textGeometry = SCNText(string: tweet_text, extrusionDepth: 1.0)
        textGeometry.font = UIFont(name: "Avenir", size: 1)
        textGeometry.firstMaterial!.diffuse.contents = UIColor.black
        let textNode = SCNNode(geometry: textGeometry)
        
        // Update object's pivot to its center
        (min, max) = textGeometry.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation(min.x, max.y, min.z + 0.5 * (max.z - min.z))
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        
        let planeWidth: Float = 0.25
        let planeHeight: Float =  padding + username_size / 2 + spacing + (max.y - min.y) * 0.01 + padding
        
        usernameNode.simdPosition = simd_float3.init(x: planeWidth * -1.0 / 2.0 + padding, y: planeHeight / 2.0 - padding, z: 0)
        textNode.simdPosition = simd_float3.init(x: planeWidth * -1.0 / 2.0 + padding, y:  planeHeight/2 - padding - 0.01 , z: 0)
        
        let plane = SCNPlane(width: CGFloat(planeWidth), height: CGFloat(planeHeight))
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(rgb: 0xF9F9F9)
        plane.firstMaterial = planeMaterial
        let parentNode = SCNNode(geometry: plane) // this node will hold our text node
        
        let yFreeConstraint = SCNBillboardConstraint()
        yFreeConstraint.freeAxes = .Y // optionally
        parentNode.constraints = [yFreeConstraint] // apply the constraint to the parent node
        (min, max) = plane.boundingBox
        parentNode.pivot = SCNMatrix4MakeTranslation(max.x , 0, min.z + 0.5 * (max.z - min.z))
        parentNode.simdPosition = billboard_position

        //////////////////////////////////////////////////////////////////////////////////////////////////
        parentNode.addChildNode(usernameNode)
        parentNode.addChildNode(textNode)
        addChildNode(parentNode)
        return planeHeight
    }
    
    
    func move(_ position: SCNVector3)  {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        self.position = position
        opacity = 1
        SCNTransaction.commit()
    }
    
    func hide()  {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        opacity = 0
        SCNTransaction.commit()
    }
    
    func show()  {
        opacity = 0
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        opacity = 1
        SCNTransaction.commit()
    }
}

private extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
