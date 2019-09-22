//
//  PlaylistViewController.swift
//  Aux
//
//  Created by Daniel on 4/30/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import SDWebImage
import Spartan
import FirebaseDatabase

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MyCustomCellDelegator {
    
    @IBOutlet weak var playlistTableView: UITableView!
    
    @IBOutlet weak var playlistThumbnailImage: UIImageView!
    
    @IBOutlet weak var playlistNameLabel: UILabel!
    
    @IBOutlet weak var numSongsLabel: UILabel!
    
    var currentPlaylist: Playlist!
    
    var playlistTracks: [PlaylistTrack]!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        playlistTableView.delegate = self
        playlistTableView.dataSource = self
        
        playlistTableView.backgroundColor = UIColor(rgb: 0x252525)
        
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
        
        _ = Spartan.getPlaylistTracks(userId: currentPlaylist.ownerID, playlistId: currentPlaylist.playlistID, limit: 100, offset: 0, market: .us, success: { (pagingObject) in
            // Get the playlist tracks via pagingObject.items
            self.playlistTracks = pagingObject.items
            self.playlistTableView.reloadData()
            
        }, failure: { (error) in
            print(error)
        })
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlistTracks == nil {
            return 0
        } else {
            return playlistTracks.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Spotify Playlist"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = .white
            headerView.textLabel?.font = UIFont.init(name: "Raleway-v4020-Medium", size: 13)
            headerView.backgroundView?.backgroundColor = UIColor(rgb: 0x252525)
            headerView.tintColor = UIColor(rgb: 0x252525)
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "songCell") as? SearchCell {
            
            cell.delegate = self
            
            // Get track from Current Playlist and unpack
            let track = unpackPlaylistTrack(theTrack: playlistTracks[indexPath.row])
            
            // Set text
            cell.songLabel.text = track.name
    
            // Set track's artist
            cell.artistLabel.text = track.artist
            
            // Set Play URI
            cell.playURI = track.playURI
            
            // Set track link
            cell.trackLink = track.trackLink
            
            // Get Art URL and set image
            let albumArtURL = track.imageURL
            cell.albumArtImageURI = albumArtURL

            if albumArtURL == "none" {
                cell.albumArtImage.image = UIImage(named: "defaultAlbum")
            } else {
                cell.albumArtImage.sd_setImage(with: URL(string: albumArtURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                    // Perform operation.
                    cell.albumArtImage.image = image
                })
            }
            
            cell.songLabel.highlightedTextColor = UIColor(rgb: 0xEA711A)
            cell.artistLabel.highlightedTextColor = UIColor(rgb: 0xEA711A)
            
            let selectionColor = UIView()
            selectionColor.backgroundColor = .clear
            cell.selectedBackgroundView = selectionColor
            
            cell.backgroundColor = UIColor(rgb: 0x252525)
            
            return cell
        }
        
        return UITableViewCell()
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
        
        // Get Play URI
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        let track = playlistTracks[indexPath.row].track
//
//        var trackArtistString = ""
//
//        var numArtists = 0
//        for artist in track!.artists {
//            if numArtists == 0 {
//                trackArtistString += artist.name
//            } else {
//                trackArtistString += ", " + artist.name
//            }
//            numArtists += 1
//        }
//
//        let currentTrack = Track(name: track!.name, artist: trackArtistString, imageURL: track!.album.images[0].url, playURI: track!.uri, track!.)
        
        // Get track from Current Playlist and unpack
        let track = unpackPlaylistTrack(theTrack: playlistTracks[indexPath.row])
        
        let currentTrack = Track(name: track.name, artist: track.artist, imageURL: track.imageURL, playURI: track.playURI, trackLink: track.trackLink)
        
        nowPlaying = currentTrack
        
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
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchPlayerState"), object: nil)
            
        } else { // Joined Session Active
            updatedFromJoinedSession = true
            let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
            groupSessionRef.updateChildValues(["updatedFromJoinedSession" : true])
            
            updateFirebaseCurrentSong()
            
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func callSegueFromCell(myData dataobject: Any) {
        performSegue(withIdentifier: "toSongOptions", sender: dataobject)
    }
    
    @IBAction func playlistOptionsButton(_ sender: Any) {
        performSegue(withIdentifier: "toPlaylistOptions", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSongOptions" {
            if let destination = segue.destination as? SongOptionsViewController {
                if let track: Track = sender as! Track? {
                    destination.selectedTrack = track
                }
            }
        } else if segue.identifier == "toPlaylistOptions" {
            if let destination = segue.destination as? PlaylistOptionsViewController {
                destination.currentPlaylist = currentPlaylist
                destination.playlistTracks = playlistTracks
            }
        }
        
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
