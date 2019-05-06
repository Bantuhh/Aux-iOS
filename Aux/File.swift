//
//  File.swift
//  Aux
//
//  Created by Daniel on 4/21/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import Foundation
import Spartan
import FirebaseDatabase

// OAuth token for Spartan API
var authorizationToken: String?

var lastPlayerState: SPTAppRemotePlayerState?

var theSessionViewController: SessionViewController?


var currentUsername: String?

// User prof pic
var userProfilePictureURL: String?

// Current Song
var nowPlaying: Track?


// Group Session Key
var groupSessionKey: String!

var groupSessionIsActive = false

var joinedGroupSessionIsActive = false

var joinedSessionSongIsPlaying: Bool!

var updatedFromJoinedSession = false

func updateFirebaseCurrentSong() {
    
    let ref = Database.database().reference()
    let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
    let currentSongRef = groupSessionRef.child("Current Song")
    
    var currentSong: [String:String] = [:]
    if nowPlaying != nil {
        currentSong = ["name": nowPlaying?.name, "artist": nowPlaying?.artist, "imageURL": nowPlaying?.imageURL, "playURI": nowPlaying?.playURI] as! [String : String]
    } else {
        currentSong = ["name": "Dopamine", "artist": "Franc Moody", "imageURL": "https://i.scdn.co/image/c0799a88b3d87c67fbb94c187c0671048da8ae20", "playURI": "spotify:track:2MTSo2SGQ0oVKgPu99x3Df"]
    }
    currentSongRef.updateChildValues(currentSong)
    
    
}

func updateFirebaseCurrentQueue() {
    
    let ref = Database.database().reference()
    let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
    // Change whole Queue child
    let queueRef = groupSessionRef.child("Queue")
    queueRef.removeValue()
    let queueDict = currentQueueToDictionary(queue: currentQueue)
    queueRef.updateChildValues(queueDict)
    
    
}




var establishedSpotifyConnection = false

var currentQueue = [Track]()

struct Track {
    var name: String
    var artist: String
    var imageURL: String
    var playURI: String
    
}

func currentQueueToDictionary(queue: [Track])-> [String : AnyObject] {
    
    var dict: [String : AnyObject] = [:]
    
    
    for (index, track) in queue.enumerated() {
        
        var trackDict: [String:String] = [:]
        
        trackDict["name"] = track.name
        trackDict["artist"] = track.artist
        trackDict["imageURL"] = track.imageURL
        trackDict["playURI"] = track.playURI
        
        let key = "track" + String(index)
        dict[key] = trackDict as AnyObject
        
        
    }
    
    return dict
    
    
}

func dictionaryToQueue(dict: [String : AnyObject])-> [Track] {
    
    var queueArr: [Track] = []
    
    let numTracks = dict.count
    
    if numTracks == 0 {
        return queueArr
    }
    
    for index in 0...(numTracks) {
        if index == numTracks {
            break
        }
        
        let key = "track" + String(index)
        
        let trackDict = dict[key] as! [String:AnyObject]
        
        let name = trackDict["name"] as! String
        let artist = trackDict["artist"] as! String
        let imageURL = trackDict["imageURL"] as! String
        let playURI = trackDict["playURI"] as! String
        
        let track = Track(name: name, artist: artist, imageURL: imageURL, playURI: playURI)
        
        queueArr.append(track)
        
        
    }
    
    return queueArr
    
    
}

struct YoutubeVideo {
    var videoTitle: String
    var videoSubTitle: String
    var viewCount: String
    var videoId: String
    var imageURL: String
    
}

struct Playlist {
    var name: String
    var numSongs: String
    var thumbnailURL: String
    //var songs: [Track]
    var playlistID: String
    var ownerID: String
}

protocol MyCustomCellDelegator {
    func callSegueFromCell(myData dataobject: Any)
}

protocol YoutubeDelegator {
    func playVideo(video: YoutubeVideo)
}

extension String {
    
    var length: Int {
        return count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
}

//var theSessionManager: SPTSessionManager?
//
//var theAppRemote: SPTAppRemote?
