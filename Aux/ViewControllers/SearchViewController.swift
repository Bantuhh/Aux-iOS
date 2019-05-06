//
//  SearchViewController.swift
//  Aux
//
//  Created by Daniel on 4/15/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import Spartan
import SDWebImage
import Alamofire
import FirebaseDatabase

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MyCustomCellDelegator {
    
    

    @IBOutlet weak var searchTableView: UITableView!
    
    @IBOutlet weak var searchBarTextField: UITextField!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var ref: DatabaseReference!
    
    
    var currentSearchItems: [SimplifiedTrack] = []
    
    var currentSearchAlbumArtURLs: [String] = []
    
    
    var youtubeSearchItems: [YoutubeVideo] = []
    
    var searchType: String!
    
    var youtubeDelegate: YoutubeDelegator!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTableView.delegate = self
        searchTableView.dataSource = self
        
        self.searchTableView.backgroundColor = UIColor(rgb: 0x252525)
        
        self.hideKeyboardWhenTappedAround()
        
        ref = Database.database().reference()
        
        youtubeDelegate = theSessionViewController
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchType == "Spotify" {
            return currentSearchItems.count
        } else if searchType == "Youtube" {
            return youtubeSearchItems.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if currentSearchItems.count == 0 && youtubeSearchItems.count == 0 {
            return "Enter a query and click a Platform to search."
        }
        if searchType == "Spotify" {
            return "Spotify Search"
        } else if searchType == "Youtube" {
            return "Youtube Search"
        }
        
        return ""
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
        
        if searchType == "Spotify" {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell") as? SearchCell {
                
                cell.delegate = self
                
                cell.platform = searchType
                
                // Get track from curr search items
                let track = currentSearchItems[indexPath.row]
                
                // Get song name and set text
                let songName: String = track.name
                
                cell.songLabel.text = songName
                
                // Get track's artist and concatenate if more than one
                var trackArtistString = ""
                
                var numArtists = 0
                for artist in track.artists {
                    if numArtists == 0 {
                        trackArtistString += artist.name
                    } else {
                        trackArtistString += ", " + artist.name
                    }
                    numArtists += 1
                }
                
                cell.artistLabel.text = trackArtistString
                
                // Get Art URL and set image
                let albumArtURL = currentSearchAlbumArtURLs[indexPath.row]
                
                cell.albumArtImageURI = albumArtURL
                
                cell.playURI = track.uri
                
                cell.albumArtImage.sd_setImage(with: URL(string: albumArtURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                    // Perform operation.
                    cell.albumArtImage.image = image
                })
                
                cell.songLabel.highlightedTextColor = UIColor(rgb: 0xEA711A)
                cell.artistLabel.highlightedTextColor = UIColor(rgb: 0xEA711A)

                let selectionColor = UIView()
                selectionColor.backgroundColor = .clear
                cell.selectedBackgroundView = selectionColor
                

                cell.backgroundColor = UIColor(rgb: 0x252525)
                
                return cell
                
            }
            
        } else if searchType == "Youtube" {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell") as? SearchCell {
                
                cell.delegate = self
                
                cell.platform = searchType
                
                // Get video from curr search items
                let video = youtubeSearchItems[indexPath.row]
                
                // Get video name and set text
                let songName: String = video.videoTitle
                
                cell.songLabel.text = songName
                
                // Get video channel and concatenate with view count
                let videoChannelNViewCount = video.videoSubTitle + " • " + video.viewCount + " views"
                
                
                cell.artistLabel.text = videoChannelNViewCount
                
                // Get Art URL and set image
                let imageURL = video.imageURL
                
                cell.albumArtImageURI = imageURL
                
                cell.playURI = video.videoId
                
                cell.albumArtImage.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "defaultAlbum"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                    // Perform operation.
                    cell.albumArtImage.image = image
                })
                
                cell.songLabel.highlightedTextColor = UIColor(rgb: 0xEA711A)
                cell.artistLabel.highlightedTextColor = UIColor(rgb: 0xEA711A)
                
                let selectionColor = UIView()
                selectionColor.backgroundColor = .clear
                cell.selectedBackgroundView = selectionColor
                
                
                cell.backgroundColor = UIColor(rgb: 0x252525)
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchType == "Spotify" {
            let track = currentSearchItems[indexPath.row]
            
            var trackArtistString = ""
            
            var numArtists = 0
            for artist in track.artists {
                if numArtists == 0 {
                    trackArtistString += artist.name
                } else {
                    trackArtistString += ", " + artist.name
                }
                numArtists += 1
            }
            
            let currentTrack = Track(name: track.name, artist: trackArtistString, imageURL: currentSearchAlbumArtURLs[indexPath.row], playURI: track.uri)
            
            nowPlaying = currentTrack
            
            if !joinedGroupSessionIsActive {
                if groupSessionIsActive {
                    updatedFromJoinedSession = false
                    let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                    groupSessionRef.updateChildValues(["updatedFromJoinedSession" : false])
                    
                    updateFirebaseCurrentSong()
                    
                    
                }
                
                appDelegate.appRemote.playerAPI?.enqueueTrackUri(track.uri, callback: { (result, error) in
                    self.appDelegate.appRemote.playerAPI?.skip(toNext: { (result, error) in
                        //todo
                    })
                })
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchPlayerState"), object: nil)
                
                
            } else {
                updatedFromJoinedSession = true
                let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
                groupSessionRef.updateChildValues(["updatedFromJoinedSession" : true])
                
                updateFirebaseCurrentSong()
                
            }
            
        } else if searchType == "Youtube" {
            let video = youtubeSearchItems[indexPath.row]
            
            youtubeDelegate.playVideo(video: video)
            
        }
    }
    
    func callSegueFromCell(myData dataobject: Any) {
        performSegue(withIdentifier: "toSongOptions", sender: dataobject)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSongOptions" {
            if let destination = segue.destination as? SongOptionsViewController {
                if let track: Track = sender as! Track? {
                    destination.selectedTrack = track
                }
            }
        }
        
    }

    
    // Mark: Spotify Code below
    
    // Search Spotify Button:
    //   gets search bar text
    //   hides search tip label\
    
    
    @IBAction func SearchSpotify(_ sender: Any) {
        
        searchType = "Spotify"
        
        let searchQuery = searchBarTextField.text!
        
        // If Connected perform search
        if establishedSpotifyConnection {
            
            spotifySearchSong(query: searchQuery)
            
        } else {
            presentAlertController(title: "No Spotify Account Detected", message: "Please go to settings and log into your account.", buttonTitle: "Ok")
        
        }
    }
    
    // Search spotify tracks
    func spotifySearchSong(query: String) {
        
        let searchQuery = query
        
        if searchQuery == "" {
            presentAlertController(title: "Search is Blank", message: "Please enter song title", buttonTitle: "Ok")
        } else {
            Spartan.search(query: searchQuery, type: .track, success: { (pagingObject: PagingObject<SimplifiedTrack>) in
                // Get the tracks via pagingObject.items
                self.currentSearchItems = pagingObject.items
                
                var trackIDs = [String]()
                for item in pagingObject.items {
                    
                    let trackID = item.uri.substring(fromIndex: 14)
                    
                    trackIDs.append(trackID)
                    
                }
                
                Spartan.getTracks(ids: trackIDs, market: .us, success: { (tracks) in
                    var albumArtURLs = [String]()
                    
                    for track in tracks {
                        
                        let album = track.album
                        
                        if album == nil {
                            albumArtURLs.append("")
                            break
                        }
                        if album?.images != nil {
                            let albumArtURL = album?.images[0].url
                            albumArtURLs.append(albumArtURL ?? "")
                            
                        } else {
                            albumArtURLs.append("")
                        }
                    }
     
                    self.currentSearchAlbumArtURLs = albumArtURLs
                        
                    self.searchTableView.reloadData()
                        
    
                }, failure: { (error) in
                    print(error)
                    
                })
                
            }, failure: { (error) in
                print(error)
            })
            
        }
    }
    
    // Mark: Youtube code below
    @IBAction func youtubeSearch(_ sender: Any) {
        
        searchType = "Youtube"
        
        let searchQuery = searchBarTextField.text!
        
        
        if searchQuery == "" {
            presentAlertController(title: "Search is Blank", message: "Please enter query.", buttonTitle: "Ok")
        } else {
            getVideoWithTextSearch(searchText: searchQuery, nextPageToken: "", completion: { (videosArray, success, nextpageToken) in
                
                if(success == true){
                    
                    var newSearchItems: [YoutubeVideo] = []
                    
                    for video in videosArray {
                        let videoTitle = video["videoTitle"] as! String
                        
                        let videoId = video["videoId"] as! String
                        
                        let videoSubTitle = video["videoSubTitle"] as! String
                        
                        let viewCount = video["viewCount"] as! String
                        
                        let imageURL = video["imageUrl"] as! String
                        
                        let youtubeVideo = YoutubeVideo(videoTitle: videoTitle, videoSubTitle: videoSubTitle, viewCount: viewCount, videoId: videoId, imageURL: imageURL)
                        
                        newSearchItems.append(youtubeVideo)
                    }
                    
                    self.youtubeSearchItems = newSearchItems
                    self.searchTableView.reloadData()
                    
                    print(newSearchItems)
                    
                } else {
                    print("Error: Could not get videosArray")
                }
                
            })
        }
    }
    
    let API_KEY = "AIzaSyBZVsqzx8LCTYC4-Gj9KlWzc-agykPUTYQ"
    
    func getVideoWithTextSearch (searchText:String, nextPageToken:String, completion:@escaping (_ videosArray : Array<Dictionary<NSString, AnyObject>>, _ success:Bool, _ nextpageToken:String)-> Void){
        
        
            
        Alamofire.SessionManager.default.session.getAllTasks { (response) in
            
            response.forEach { $0.cancel() }
            
        }
            

        //let contryCode = "us"
        
        var arrVideo: Array<Dictionary<NSString, AnyObject>> = []
        
        var arrVideoFinal: Array<Dictionary<NSString, AnyObject>> = []
        
        
        let url = "https://www.googleapis.com/youtube/v3/search"
        
        let parameters = ["q": searchText, "maxResults": 25, "part": "snippet", "type":"video", "key": API_KEY] as [String : Any]
        
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (responseData) -> Void in
            
            
            
            let isSuccess = responseData.result.isSuccess
            
            if isSuccess {
                
                let resultsDict = responseData.result.value as! Dictionary<NSString, AnyObject>
                
                
                
                let items: Array<Dictionary<NSString, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSString, AnyObject>>
                
                
                
                let arrayViewCount = NSMutableArray()
                
                for i in 0..<items.count {
                    

                    let snippetDict = items[i]["snippet"] as! Dictionary<NSString, AnyObject>
                    
                    
                    
                    if !snippetDict["title"]! .isEqual("Private video") && !snippetDict["title"]! .isEqual("Deleted video") && items[i]["id"]!["videoId"]! != nil{
                        
                        var videoDetailsDict = Dictionary<NSString, AnyObject>()
                        
                        arrayViewCount.add(items[i]["id"]!["videoId"]! as! String)
                        
                        
                        videoDetailsDict["videoTitle"] = snippetDict["title"]
                        
                        videoDetailsDict["videoSubTitle"] = snippetDict["channelTitle"]
                        
                        videoDetailsDict["channelId"] = snippetDict["channelId"]
                        
                        videoDetailsDict["imageUrl"] = ((snippetDict["thumbnails"] as! Dictionary<NSString, AnyObject>)["high"] as! Dictionary<NSString, AnyObject>)["url"]
                        
                        videoDetailsDict["videoId"] = items[i]["id"]!["videoId"]! as! String as AnyObject
                        
                        arrVideo.append(videoDetailsDict)
                        
                    }
                    
                }
                
                
                
                //Get video count
                if arrayViewCount.count > 0{
                    
                    let videoUrlString = "https://www.googleapis.com/youtube/v3/videos?part=statistics&id=\(arrayViewCount.componentsJoined(by: ","))&key=\(self.API_KEY)"
                    
                    

                    Alamofire.request(videoUrlString, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { (responseData) -> Void in
                        
                        
                        
                        let isSuccess = responseData.result.isSuccess//JSON(responseData.result.isSuccess)
                        
                        if isSuccess {
                            
                            let resultsDict = responseData.result.value as! Dictionary<NSString, AnyObject>
                            
                            let items: Array<Dictionary<NSString, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSString, AnyObject>>
                            
                            
                            
                            for i in 0..<items.count {
                                
                                
                                
                                var videoDetailsDict = arrVideo[i]
                                
                                let statisticsDict = items[i]["statistics"] as! Dictionary<NSString, AnyObject>
                                
                                videoDetailsDict["viewCount"] = statisticsDict["viewCount"]
                                
                                arrVideoFinal.append(videoDetailsDict)
                                
                            }
                            
                            DispatchQueue.main.async {
                                completion(arrVideoFinal, true, nextPageToken)
                            }
                            
                            
                        } else{
                            DispatchQueue.main.async {
                                completion(arrVideoFinal, false, nextPageToken)
                            }

                        }
                        
                    })
                    
                }else{
                    
                    DispatchQueue.main.async {
                        completion(arrVideoFinal, false, nextPageToken)
                    }
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    completion(arrVideoFinal, false, nextPageToken)
                }
                
            }
            
        })
        
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
