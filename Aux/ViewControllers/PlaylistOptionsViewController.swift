//
//  PlaylistOptionsViewController.swift
//  Aux
//
//  Created by Daniel on 4/30/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import SDWebImage
import Spartan

class PlaylistOptionsViewController: UIViewController {

    @IBOutlet weak var playlistThumbnailImage: UIImageView!
    
    @IBOutlet weak var playlistNameLabel: UILabel!
    
    @IBOutlet weak var numSongsLabel: UILabel!
    
    var currentPlaylist: Playlist!
    
    var playlistTracks: [PlaylistTrack]!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playlistNameLabel.text = currentPlaylist.name
        
        numSongsLabel.text = currentPlaylist.numSongs + " songs"
        
        if currentPlaylist.thumbnailURL == "none" {
            playlistThumbnailImage.image = UIImage(named: "defaultAlbum")
        } else {
            playlistThumbnailImage.sd_setImage(with: URL(string: currentPlaylist.thumbnailURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                // Perform operation.
                self.playlistThumbnailImage.image = image
            })
        }
    }
    
    @IBAction func addPlaylistToQueue(_ sender: Any) {
        if playlistTracks == nil {
            presentAlertController(title: "Could not Complete action.", message: "Please try again.", buttonTitle: "Ok")
            
        } else {
            for theTrack in playlistTracks {
                let trackToAdd = unpackPlaylistTrack(theTrack: theTrack)
                
                currentQueue.append(trackToAdd)
            }
            
            queueUpQueue()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadQueueTable"), object: nil)
            
            dismiss(animated: true, completion: nil)
            
            //performSegue(withIdentifier: "backToSession", sender: nil)
        }
    }
    
    func unpackPlaylistTrack(theTrack: PlaylistTrack)-> Track {
        let track = theTrack.track
        let songName: String = track!.name
        
        // Get track's artist
        var trackArtistString = ""
        var numArtists = 0
        for artist in track!.artists {
            if numArtists == 0 {
                trackArtistString += artist.name
            } else {
                trackArtistString += ", " + artist.name
            }
            numArtists += 1
        }
        
        //Get Play URI
        let playURI = track!.uri!
        
        // Get track link
        let trackLink = track!.externalUrls["spotify"]!
        
        // Get Art URL and set image
        var albumArtURL = ""
        if track!.album == nil {
            albumArtURL = "none"
        } else if track!.album.images != nil {
            albumArtURL = track!.album.images[0].url
        } else {
            albumArtURL = "none"
        }
        
        let trackToReturn = Track(name: songName, artist: trackArtistString, imageURL: albumArtURL, playURI: playURI, trackLink: trackLink)
        
        return trackToReturn
    }
    
    func queueUpQueue() {
        if !joinedGroupSessionIsActive {
            
            if groupSessionIsActive {
                updateFirebaseCurrentQueue()
            }
            
            for song in currentQueue {
                appDelegate.appRemote.playerAPI?.enqueueTrackUri(song.playURI, callback: { (result, error) in
                    
                })
            }
        } else {
            updateFirebaseCurrentQueue()
            
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func presentAlertController(title: String, message: String, buttonTitle: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        controller.view.layoutIfNeeded()
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
