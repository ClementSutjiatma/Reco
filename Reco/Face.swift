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
import FirebaseDatabase
class Face {
    let name: String
    let node: SCNNode
    var usernames: NSDictionary = [:]
    
    var twitterFilled: Bool
    var tweets: [Tweet] = []
    var hidden: Bool {
        get{
            return node.opacity != 1
        }
    }
    var timestamp: TimeInterval {
        didSet {
            updated = Date()
        }
    }
    private(set) var updated = Date()
    
    init(name: String, node: SCNNode, timestamp: TimeInterval) {
        self.name = name
        self.node = node
        self.timestamp = timestamp
        self.twitterFilled = false
        // call firebase to get usernames and initialize into dictionary
        self.fillUsernames()
    }
    
    func fillUsernames() -> Void{
        var ref: DatabaseReference!
        ref = Database.database().reference()
        ref.child("users").queryOrdered(byChild: "LastName").queryEqual(toValue: self.name.lastWord.lowercased()).observeSingleEvent(of: .value, with: { (snapshot) in

            print(snapshot.childrenCount) // I got the expected number of items
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? DataSnapshot {
                let user = rest.value as? NSDictionary
                let found = (user?["FirstName"] as? String ?? "" == self.name.firstWord.lowercased());
                if (found) {
                    print("Found for user:" + self.name)
                    // Get username dictionary
                    self.usernames = user!
                    break
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }

    }
    
    func fillTwitter() -> Void{
        var ref: DatabaseReference!
        ref = Database.database().reference()
        //get top three tweets and fill into tweets array
        if let username = self.usernames["twitter"] {
            ref.child("tweets").child(username as! String).queryOrdered(byChild: "timestamp").queryLimited(toFirst: 3).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            
            let enumerator = snapshot.children
            var billboard_position = simd_float3.init(x:0.5, y: 0, z: 0)
            var offset: Float = 0.1wor
            let padding: Float = 0.01
            while let rest = enumerator.nextObject() as? DataSnapshot {
                //print(rest.value)
                let tweet = rest.value as? NSDictionary
                offset = self.node.addTwitter(username: tweet?["user"] as! NSString, timestamp: tweet?["timestamp"] as! NSString, retweets: tweet?["retweets"] as! NSString, replies: tweet?["replies"] as! NSString, likes: tweet?["likes"] as! NSString, text: tweet?["text"] as! NSString, billboard_position: billboard_position)
                self.twitterFilled = true
                billboard_position.y -= (offset + padding)
            }
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
        }
        //initialize three tweet nodes and append to tweetNodes array
        //for each tweet in tweets
        //initialize tweetnode and append to Twitter parent node
    }
}

extension Date {
    func isAfter(seconds: Double) -> Bool {
        let elapsed = Date.init().timeIntervalSince(self)
        
        if elapsed > seconds {
            return true
        }
        return false
    }
}

