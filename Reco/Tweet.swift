//
//  Tweet.swift
//  Reco
//
//  Created by Clement Arnett Sutjiatma on 8/19/18.
//  Copyright © 2018 Reco. All rights reserved.
//

import Foundation
import ARKit
class Tweet //extension SCNNode
{
    let username: String
    var timestamp: TimeInterval
    let retweets: NSNumber
    let replies: NSNumber
    let likes: NSNumber
    let text: NSString
    
    init(username: String, timestamp: TimeInterval, retweets: NSNumber, replies: NSNumber, likes: NSNumber, text:NSString){
    self.username = username
    self.timestamp = timestamp
    self.retweets = retweets
    self.replies = replies
    self.likes = likes
    self.text = text
    }
    
    
    

}
