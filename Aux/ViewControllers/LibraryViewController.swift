//
//  LibraryViewController.swift
//  Aux
//
//  Created by Daniel on 4/30/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import Spartan
import SDWebImage
import FirebaseDatabase

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MyCustomCellDelegator {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var libraryTableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var favorites: [Track] = []
    var favoritesAlbumArtURLs: [String] = []
    
    var playlists: [Playlist] = []
    var playlistThumbnailURLs: [String] = []
    
    var currentPagingObject: PagingObject<SavedTrack>!
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        libraryTableView.delegate = self
        libraryTableView.dataSource = self
        
        libraryTableView.backgroundColor = UIColor(rgb: 0x252525)
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : UIFont.init(name: "Raleway-v4020-Regular", size: 12)!]
        
        segmentedControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        
        // Get Spotify Playlists
        _ = Spartan.getMyPlaylists(limit: 25, offset: 0, success: { (pagingObject) in
            // Get the playlists via pagingObject.items
            var currentPlaylists: [Playlist] = []
            var currentThumbnailURLs: [String] = []
            
            for playlist in pagingObject.items {
                let playlistName = playlist.name
                let playlistNumSongs = String(playlist.tracksObject.total)
                let playlistThumbnailURL = playlist.images[0].url
                
                currentThumbnailURLs.append(playlistThumbnailURL!)
                
                let ownerID = playlist.owner.href?.substring(fromIndex: 33)
                let playlistURI = playlist.uri
                let playlistID = playlistURI?.substring(fromIndex: 17)
                
                let playlistLink = playlist.externalUrls["spotify"]
                
                let currPlaylist = Playlist(name: playlistName!, numSongs: playlistNumSongs, thumbnailURL: playlistThumbnailURL!, playlistID: playlistID!, ownerID: ownerID!, playlistLink: playlistLink!)
                
                currentPlaylists.append(currPlaylist)
            }
            
            self.playlists = currentPlaylists
            self.playlistThumbnailURLs = currentThumbnailURLs
            
        }, failure: { (error) in
            print(error)
        })
        
        // Get Spotify Favorites
        _ = Spartan.getSavedTracks(limit: 50, offset: 0, market: .us, success: { (pagingObject) in
            // Get the saved tracks via pagingObject.items
            self.makeFavoritesFromPagingObjects(savedTracks: pagingObject.items)
            
        }, failure: { (error) in
            print(error)
        })
        
        _ = Spartan.getSavedTracks(limit: 50, offset: 50, market: .us, success: { (pagingObject) in
            // Get the saved tracks via pagingObject.items
            self.makeFavoritesFromPagingObjects(savedTracks: pagingObject.items)
            
        }, failure: { (error) in
            print(error)
        })
        
        
        
        
    }
    
    func makeFavoritesFromPagingObjects(savedTracks: [SavedTrack]) {
        var currentTracks: [Track] = []
        var currentImageURLs: [String] = []
        
        for track in savedTracks {
            let currentTrack = track.track
            
            let trackName = currentTrack?.name
            
            var trackArtistString = ""
            var numArtists = 0
            for artist in currentTrack!.artists {
                if numArtists == 0 {
                    trackArtistString += artist.name
                } else {
                    trackArtistString += ", " + artist.name
                }
                numArtists += 1
            }
            
            var trackAlbumImageURL = ""
            let album = currentTrack?.album
            
            if album == nil {
                trackAlbumImageURL = ""
            } else if album?.images != nil {
                trackAlbumImageURL = (album?.images[0].url)!
            } else {
                trackAlbumImageURL = ""
            }
            
            currentImageURLs.append(trackAlbumImageURL)
            
            let playURI = currentTrack?.uri
            
            let trackLink = currentTrack?.externalUrls["spotify"]
            
            let trackToAdd = Track(name: trackName!, artist: trackArtistString, imageURL: trackAlbumImageURL, playURI: playURI!, trackLink: trackLink!)
            
            currentTracks.append(trackToAdd)
        }
        
        self.favorites += currentTracks
        self.favoritesAlbumArtURLs += currentImageURLs
        
        self.libraryTableView.reloadData()
    }
    
    // Update Table when switching segments
    @IBAction func favoritesPlaylistsSegmentedController(_ sender: Any) {
        libraryTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // favorites
            return favorites.count
        case 1:  // playlists
            return playlists.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // favorites
            return "Your Spotify Favorites"
        case 1:  // playlists
            return "Your Spotify Playlists"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = .white
            headerView.textLabel?.font = UIFont.init(name: "Raleway-v4020-Bold", size: 12)
            headerView.backgroundView?.backgroundColor = UIColor(rgb: 0x252525)
            headerView.tintColor = UIColor(rgb: 0x252525)
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // favorites
            if let cell = tableView.dequeueReusableCell(withIdentifier: "songCell") as? SearchCell {
                
                cell.delegate = self
                
                // Get track from curr search items
                let track = favorites[indexPath.row]
                
                // Get song name and set text
                let songName: String = track.name
                
                cell.songLabel.text = songName
                
                // Get track's artist and concatenate if more than one
                let trackArtistString = track.artist
                
                cell.artistLabel.text = trackArtistString
                
                cell.playURI = track.playURI
                
                cell.trackLink = track.trackLink
                
                // Get Art URL and set image
                let albumArtURL = favoritesAlbumArtURLs[indexPath.row]
                
                if albumArtURL == "" {
                    cell.albumArtImage.image = UIImage(named: "defaultAlbum")
                    cell.albumArtImageURI = albumArtURL
                } else {
                    cell.albumArtImageURI = albumArtURL

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
        case 1:  // playlists
            if let cell = tableView.dequeueReusableCell(withIdentifier: "playlistCell") as? PlaylistCell {
                
                cell.delegate = self
                
                // Get track from curr search items
                let playlist = playlists[indexPath.row]
                
                // Get song name and set text
                cell.playlistNameLabel.text = playlist.name
                
                // Get numSongs and set text
                cell.numSongsLabel.text = playlist.numSongs + " songs"
                cell.numSongs = playlist.numSongs
                
                // Set playlist ID
                cell.playlistID = playlist.playlistID
                
                // Set owner ID
                cell.ownerID = playlist.ownerID
                
                // Set playlist link
                cell.playlistLink = playlist.playlistLink
                
                // Get Art URL and set image
                let thumbnailURL = playlistThumbnailURLs[indexPath.row]
                
                cell.playlistThumbnailURL = thumbnailURL
                
                cell.playlistThumbnail.sd_setImage(with: URL(string: thumbnailURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                    // Perform operation.
                    cell.playlistThumbnail.image = image
                })
                
                cell.backgroundColor = UIColor(rgb: 0x252525)
                
                cell.selectionStyle = .none
                
                return cell
            }
        default:
            break
        }
        
        return UITableViewCell()
    
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // favorites
            let track = favorites[indexPath.row]
            
            nowPlaying = track
            
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
            
        
        case 1:  // playlists
            break
        default:
            break
        }
        

        
    }
    
    func callSegueFromCell(myData dataobject: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // favorites
            performSegue(withIdentifier: "toSongOptions", sender: dataobject)
        case 1:  // playlists
            performSegue(withIdentifier: "toPlaylistView", sender: dataobject)
        default:
            break
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSongOptions" {
            if let destination = segue.destination as? SongOptionsViewController {
                if let track: Track = sender as! Track? {
                    destination.selectedTrack = track
                }
            }
        } else if segue.identifier == "toPlaylistView" {
            if let destination = segue.destination as? PlaylistViewController {
                if let playlist: Playlist = sender as! Playlist? {
                    destination.currentPlaylist = playlist
                }
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
