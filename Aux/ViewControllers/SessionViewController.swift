//
//  SessionViewController.swift
//  Aux
//
//  Created by Daniel on 4/10/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth
import SDWebImage
import youtube_ios_player_helper
import FirebaseDatabase

class SessionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, YoutubeDelegator, YTPlayerViewDelegate {
    
    
    @IBOutlet weak var currSongName: UILabel!
    
    @IBOutlet weak var currArtistName: UILabel!
    
    @IBOutlet weak var QueueTableView: UITableView!
    
    @IBOutlet weak var currAlbumArtImage: UIImageView!
    
    var currAlbumArtURL: String?
    
    var currTrackLink: String!
    
    @IBOutlet weak var playAndPauseButton: UIButton!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var ref: DatabaseReference!
    
    @IBOutlet weak var youtubePlayer: YTPlayerView!
    
    var currentTypePlaying: String = "Spotify"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgb: 0x252525)
        self.QueueTableView.backgroundColor = UIColor(rgb: 0x252525)
        view.sendSubviewToBack(youtubePlayer)
        youtubePlayer.isHidden = true
        
        view.sendSubviewToBack(currAlbumArtImage)
        
        youtubePlayer.delegate = self
        
        ref = Database.database().reference()
        
        QueueTableView.dataSource = self
        QueueTableView.delegate = self
        QueueTableView.isEditing = false
        
        if nowPlaying != nil {
            currAlbumArtURL = nowPlaying?.imageURL
        }
        
        fetchPlayerState()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchPlayerState(_:)), name: Notification.Name(rawValue: "fetchPlayerState"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadQueueTable(_:)), name: Notification.Name(rawValue: "reloadQueueTable"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentSong(_:)), name: Notification.Name(rawValue: "updateCurrentSong"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateIfJoinedSessionSongIsPlaying(_:)), name: Notification.Name(rawValue: "updateIfJoinedSessionSongIsPlaying"), object: nil)
        

        theSessionViewController = self
        
        
    }
    
    // Check how many songs are in the queue
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentQueue.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if currentQueue.count == 0 {
            return "Add songs to the Queue!"
        }
        return "Queue"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = .white
            headerView.textLabel?.font = UIFont.init(name: "Raleway-v4020-Bold", size: 12)
            headerView.backgroundView?.backgroundColor = UIColor(rgb: 0x252525)
            headerView.tintColor = UIColor(rgb: 0x252525)
        }
        
    }
    
    // Get the Queue and display song name and artist
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "queueCell") as? QueueCell {
            
            let correctCell = currentQueue[indexPath.row]
        
        
            cell.songNameLabel.text = correctCell.name
            
            cell.artistNameLabel.text = correctCell.artist
            
            cell.albumArtImage.sd_setImage(with: URL(string: correctCell.imageURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                // Perform operation.
                cell.albumArtImage.image = image
            })
            
            cell.backgroundColor = UIColor(rgb: 0x252525)
            
            return cell
            
        }
        
        return UITableViewCell()
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            skip(0)
            
        } else {
        
            let track = currentQueue[indexPath.row]
            
            nowPlaying = track
            
            currAlbumArtURL = track.imageURL
            
            currTrackLink = track.trackLink
            
            if !joinedGroupSessionIsActive {
                if groupSessionIsActive {
                    updatedFromJoinedSession = false
                    let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                    groupSessionRef.updateChildValues(["updatedFromJoinedSession" : false])
                    
                    updateFirebaseCurrentSong()
                    
                }
                
                appDelegate.appRemote.playerAPI?.enqueueTrackUri(track.playURI, callback: { (result, error) in
                    self.appDelegate.appRemote.playerAPI?.skip(toNext: { (result, error) in
                        //todo
                    })
                })
                
                fetchPlayerState()
                
                
                
            } else { // Joined Session Active
                updateFirebaseCurrentSong()
                updatedFromJoinedSession = true
                
                let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                groupSessionRef.updateChildValues(["updatedFromJoinedSession" : true])
                
            }
            
            currentQueue.remove(at: indexPath.row)
            
            queueUpQueue()
            
            QueueTableView.reloadData()
        }
        
    }

    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")
            
            currentQueue.remove(at: indexPath.row)
            QueueTableView.deleteRows(at: [indexPath], with: .automatic)
            
            queueUpQueue()
                
        
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = currentQueue[sourceIndexPath.row]
        currentQueue.remove(at: sourceIndexPath.row)
        currentQueue.insert(movedObject, at: destinationIndexPath.row)
        
        
        queueUpQueue()
        
            
        QueueTableView.reloadData()
        
    }
    
    
    func queueUpQueue() {
        if !joinedGroupSessionIsActive {
            for song in currentQueue {
                appDelegate.appRemote.playerAPI?.enqueueTrackUri(song.playURI, callback: { (result, error) in
                    
                })
            }
        }
        
        if groupSessionIsActive || joinedGroupSessionIsActive {
            updateFirebaseCurrentQueue()
        }
    }
    
    
    @IBAction func songOptionsButtonPressed(_ sender: Any) {
//        let track = Track(name: self.currSongName.text!, artist: self.currArtistName.text!, imageURL: currAlbumArtURL, playURI: (lastPlayerState?.track.uri)!, trackLink: lastPlayerState?.track.)
        
        let track = nowPlaying
        
        performSegue(withIdentifier: "goToSongOptions", sender: track)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSongOptions" {
            if let destination = segue.destination as? SongOptionsViewController {
                if let track: Track = sender as! Track? {
                    destination.selectedTrack = track
                    destination.albumImage = currAlbumArtImage.image!
                }
            }
        }
        
    }
    
    
    @IBAction func groupSessionButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "toGroupSession", sender: sender)
    }
    

    @IBAction func restart(_ sender: Any) {
        if !joinedGroupSessionIsActive {
            appDelegate.appRemote.playerAPI?.enqueueTrackUri((lastPlayerState?.track.uri)!, callback: { (result, error) in
                self.appDelegate.appRemote.playerAPI?.skip(toNext: { (result, error) in
                    //todo
                })
            })
        }
    }
    
    @IBAction func playNpause(_ sender: Any) {
        if currentTypePlaying == "Spotify" {
            
            
            if !joinedGroupSessionIsActive {
                if !appDelegate.appRemote.isConnected { // Lost Connection to Spotify
                    performSegue(withIdentifier: "toMusicLogin", sender: nil)
                    
                    presentAlertController(title: "You have disconnected from spotify.", message: "Please reconnect.", buttonTitle: "Ok")
                    
                    
                } else if groupSessionIsActive { // Group Session Active
                    let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                    
                    if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
                        appDelegate.appRemote.playerAPI?.resume(nil)
                        groupSessionRef.updateChildValues(["isSongPlaying" : true])
                        
                    } else {
                        appDelegate.appRemote.playerAPI?.pause(nil)
                        groupSessionRef.updateChildValues(["isSongPlaying" : false])
                        
                    }
                    
                    
                } else { // Solo Session Playing
                    if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
                        appDelegate.appRemote.playerAPI?.resume(nil)
                        
                        
                    } else {
                        appDelegate.appRemote.playerAPI?.pause(nil)
                        
                        
                    }
                }
                
                
            } else { // Joined Group Session Active
                let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                
                // Firebase Update Player State
                if joinedSessionSongIsPlaying {
                    groupSessionRef.updateChildValues(["isSongPlaying" : false])
                    playAndPauseButton.setBackgroundImage(UIImage(named: "PlayButton"), for: .normal)
                    
                } else {
                    groupSessionRef.updateChildValues(["isSongPlaying" : true])
                    playAndPauseButton.setBackgroundImage(UIImage(named: "PauseButton"), for: .normal)
                    
                }
                
            }
            
        } else if currentTypePlaying == "Youtube" {
            if youtubePlayer.playerState().rawValue == 1 { // Playing
                youtubePlayer.stopVideo()
            } else {
                youtubePlayer.playVideo()
            }
            
            
            
        }
    }
    
    @objc func updateIfJoinedSessionSongIsPlaying(_ notification: Notification) {
        if joinedSessionSongIsPlaying {
            playAndPauseButton.setBackgroundImage(UIImage(named: "PauseButton"), for: .normal)
            
        } else {
            playAndPauseButton.setBackgroundImage(UIImage(named: "PlayButton"), for: .normal)
            
        }
        
    }
    
    
    @IBAction func skip(_ sender: Any) {
        if !joinedGroupSessionIsActive {
            if !appDelegate.appRemote.isConnected{
                performSegue(withIdentifier: "toMusicLogin", sender: nil)
                
                presentAlertController(title: "You have disconnected from spotify.", message: "Please reconnect.", buttonTitle: "Ok")
                
                
            } else {
                nowPlaying = currentQueue[0]
                
                self.appDelegate.appRemote.playerAPI?.skip(toNext: { (result, error) in
                    //todo
                })
                
                fetchPlayerState()
                
                if groupSessionIsActive {
                    updateFirebaseCurrentSong()
                    
                    updatedFromJoinedSession = false
                    let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                    groupSessionRef.updateChildValues(["updatedFromJoinedSession" : false])
                    
                }
                
            }
            
        } else { // Joined Session Active
            updatedFromJoinedSession = true
            let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
            groupSessionRef.updateChildValues(["updatedFromJoinedSession" : true])
            
            nowPlaying = currentQueue[0]
            updateFirebaseCurrentSong()
            currAlbumArtURL = currentQueue[0].imageURL
            currTrackLink = currentQueue[0].trackLink
            currentQueue.remove(at: 0)
            queueUpQueue()
            QueueTableView.reloadData()
            
        }
    }
    

    @IBOutlet weak var editQueueButton: UIButton!
    
    var editingQueue = false
    @IBAction func editQueueButton(_ sender: Any) {
        if editingQueue == false {
            QueueTableView.isEditing = true
            editQueueButton.setTitle("Done", for: [])
            editQueueButton.setTitleColor(UIColor(rgb: 0xEA711A), for: [])
            editingQueue = true
        } else {
            QueueTableView.isEditing = false
            editQueueButton.setTitle("Edit Queue", for: [])
            editQueueButton.setTitleColor(.white, for: [])
            editingQueue = false
        }
    }
    
    @objc func fetchPlayerState(_ notification: Notification) {
        fetchPlayerState()
        
    }
    
    @objc func reloadQueueTable(_ notification: Notification) {
        self.QueueTableView.reloadData()

    }
    
    
    func update(playerState: SPTAppRemotePlayerState) {
        
        // Get artwork from spotify player for current song playing, called from fetchplayerstate
        if lastPlayerState?.track.uri != playerState.track.uri {
            fetchArtwork(for: playerState.track)
        
        }
        lastPlayerState = playerState
        
        
        // If next song up is the same as first in queue remove that song
        if currentQueue.count > 0 {
            if lastPlayerState?.track.uri == currentQueue[0].playURI {
                currAlbumArtURL = currentQueue[0].imageURL
                currTrackLink = currentQueue[0].trackLink
                currentQueue.remove(at: 0)
                queueUpQueue()
                QueueTableView.reloadData()
            }
        }
        
        if nowPlaying != nil {
            // If song updated by itself
            if nowPlaying?.playURI != playerState.track.uri {
                let track = Track(name: playerState.track.name, artist: playerState.track.artist.name, imageURL: currAlbumArtURL ?? "", playURI: playerState.track.uri, trackLink: currTrackLink ?? "")
                
                nowPlaying = track
            }
            
        } else { // else if nowPlaying hasn't been set
            let track = Track(name: playerState.track.name, artist: playerState.track.artist.name, imageURL: currAlbumArtURL ?? "", playURI: playerState.track.uri, trackLink: currTrackLink ?? "")
            
            nowPlaying = track
        }
        
        
        currSongName.text = playerState.track.name
        currArtistName.text = playerState.track.artist.name
        
        
        if playerState.isPaused {
            playAndPauseButton.setBackgroundImage(UIImage(named: "PlayButton"), for: .normal)
        } else {
            playAndPauseButton.setBackgroundImage(UIImage(named: "PauseButton"), for: .normal)
        }
        
        
        // Set Current Song in Firebase
        if groupSessionIsActive {
            updateFirebaseCurrentSong()
        }
        
    }
    
    func fetchArtwork(for track: SPTAppRemoteTrack) {
        appDelegate.appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                self?.currAlbumArtImage.image = image
            }
        })
    }

    func fetchPlayerState() {
        appDelegate.appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
    }
    
    
    // Joined Group Session Methods:
    @objc func updateCurrentSong(_ notification: Notification) {
        currSongName.text = nowPlaying?.name
        currArtistName.text = nowPlaying?.artist
        
        currTrackLink = nowPlaying?.trackLink
        
        currAlbumArtURL = nowPlaying?.imageURL
        currAlbumArtImage.sd_setImage(with: URL(string: nowPlaying!.imageURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
            // Perform operation.
            self.currAlbumArtImage.image = image
        })
        
    }
    

    
    fileprivate func presentAlertController(title: String, message: String, buttonTitle: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        controller.view.layoutIfNeeded()
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }
    
    
    
    
    
    // Youtube:
    func playVideo(video: YoutubeVideo) {
        
//        let playerVars: Dictionary = ["autoplay": "1", "controls": "0", "fs": "0", "loop": "0", "modestbranding": "1", "playsinline": "1", "rel": "0"]
        
        let playerVars = ["autoplay": 1, "controls": 0, "fs": 0, "loop": 0, "modestbranding": 1, "playsinline": 1, "rel": 0, "origin": "http://www.youtube.com"] as [String : Any]
        
        youtubePlayer.load(withVideoId: video.videoId, playerVars: playerVars)
        
        currAlbumArtImage.isHidden = true
        
        currentTypePlaying = "Youtube"
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        print("Player state did change. Raw Value: ", state.rawValue)
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.playVideo()
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
