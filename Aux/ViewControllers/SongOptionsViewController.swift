//
//  SongOptionsController.swift
//  Aux
//
//  Created by Daniel on 4/27/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit

import SDWebImage

class SongOptionsViewController: UIViewController {
    
    var selectedTrack: Track?
    
    var albumImage: UIImage?

    @IBOutlet weak var albumArtImage: UIImageView!
    
    @IBOutlet weak var songNameLabel: UILabel!
    
    @IBOutlet weak var artistNameLabel: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        songNameLabel.text = selectedTrack?.name
        
        artistNameLabel.text = selectedTrack?.artist
        
        if selectedTrack?.imageURL == "none" {
            albumArtImage.image = albumImage
        } else {
            albumArtImage.sd_setImage(with: URL(string: selectedTrack!.imageURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                // Perform operation.
                self.albumArtImage.image = image
            })
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func addToQueue(_ sender: Any) {
        
        currentQueue.append(selectedTrack!)
        
        queueUpQueue()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadQueueTable"), object: nil)
        
        dismiss(animated: true, completion: nil)
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
    
    @IBAction func addToPlaylist(_ sender: Any) {
    }
    
    @IBAction func viewOnSpotify(_ sender: Any) {
    }
    
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
