//
//  GroupSessionViewController.swift
//  Aux
//
//  Created by Daniel on 5/1/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SDWebImage


class GroupSessionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var ref: DatabaseReference!
    
    @IBOutlet weak var groupSessionTableView: UITableView!
    
    
    @IBOutlet weak var groupCodeTitleLabel: UILabel!
    
    @IBOutlet weak var groupCodeLabel: UILabel!
    
    @IBOutlet weak var groupMemberTitleLabel: UILabel!
    
    @IBOutlet weak var topLine: UIImageView!
    
    @IBOutlet weak var leaveOrEndSessionButton: UIButton!
    
    
//    var groupMembersDictionary: [String:AnyObject] = ["member1": (["name": currentUsername, "pictureURL": userProfilePictureURL]) as AnyObject]
    var groupMembersDictionary: [String:AnyObject]!
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgb: 0x252525)
        
        groupSessionTableView.backgroundColor = UIColor(rgb: 0x252525)
        
        groupSessionTableView.delegate = self
        groupSessionTableView.dataSource = self
        
        ref = Database.database().reference()
        
        if groupSessionIsActive || joinedGroupSessionIsActive {
            updateViewIfSessionActive()
            updateGroupMembersTable()
            groupCodeLabel.text = groupSessionKey
            
        } else {
            groupMemberTitleLabel.isHidden = true
            topLine.isHidden = true
            groupCodeTitleLabel.isHidden = true
            groupCodeLabel.isHidden = true
            groupSessionTableView.isHidden = true
            leaveOrEndSessionButton.isHidden = true
            
        }
        
        view.addSubview(beginGroupSessionButton)
        beginGroupSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        beginGroupSessionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -75).isActive = true
        beginGroupSessionButton.sizeToFit()
        beginGroupSessionButton.addTarget(self, action: #selector(didTapBeginSesh(_:)), for: .touchUpInside)
        
        view.addSubview(joinGroupSessionButton)
        joinGroupSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        joinGroupSessionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 75).isActive = true
        joinGroupSessionButton.sizeToFit()
        joinGroupSessionButton.addTarget(self, action: #selector(didTapJoinSesh(_:)), for: .touchUpInside)
        
        view.addSubview(orLabel)
        orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        orLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        // Setup a Listener
        NotificationCenter.default.addObserver(self, selector: #selector(updateGroupSessionView(_:)), name: Notification.Name(rawValue: "updateGroupSessionView"), object: nil)
    }
    
    fileprivate lazy var beginGroupSessionButton = GroupSessionButton(title: "Begin Group Session")
    fileprivate lazy var joinGroupSessionButton = GroupSessionButton(title: "Join a Group Session")
    
    fileprivate lazy var orLabel: UILabel = {
        let label = UILabel()
        label.text = "Or"
        label.font = UIFont.init(name: "Raleway-v4020-Medium", size: 16)!
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    // Table view methods:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if groupMembersDictionary == nil {
            return 0
        }
        return groupMembersDictionary.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell") as? GroupMemberCell {
            
            let key = "member" + String(indexPath.row + 1)
            
            let memberDict = groupMembersDictionary[key] as! [String:String]
            
            if key == "member1" {
                cell.memberNameLabel.text = memberDict["name"]! + " (Master)"
                cell.memberNameLabel.textColor = UIColor(rgb: 0xEA711A)
            } else {
                cell.memberNameLabel.text = memberDict["name"]
            }
            
            let pictureURL = memberDict["pictureURL"]
            
            cell.memberProfilePicture.sd_setImage(with: URL(string: pictureURL!), placeholderImage: UIImage(named: "Group Member"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                // Perform operation.
                cell.memberProfilePicture.image = image
            })
            
            cell.backgroundColor = UIColor(rgb: 0x252525)
            
            return cell
        }
        
        return UITableViewCell()
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
    
    @objc func didTapBeginSesh(_ button: UIButton) {
        
        groupSessionIsActive = true
        updateViewIfSessionActive()
        
        
        groupSessionKey = randomKey(length: 6)
        groupCodeLabel.text = groupSessionKey
        
        
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        
        groupSessionRef.updateChildValues(["isSessionEnding" : false])
        
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            groupSessionRef.updateChildValues(["isSongPlaying" : false])
            
        } else {
            groupSessionRef.updateChildValues(["isSongPlaying" : true])
            
        }
        
        setupIsSongPlayingListener()
        
        // Set yourself as member1 in Group Members
        let groupMembersRef = groupSessionRef.child("Group Members")
        let groupMember = ["name": currentUsername, "pictureURL": userProfilePictureURL]
        groupMembersRef.child("member1").updateChildValues(groupMember)
        

        // Update Table
        updateGroupMembersTable()
        
        
        // Set Current Song
        updateFirebaseCurrentSong()
        // Setup Listener for Current Song
        let currentSongRef = groupSessionRef.child("Current Song")
        
        _ = currentSongRef.observe(DataEventType.value, with: { (snapshot) in
            let songDict = snapshot.value as? [String : AnyObject] ?? [:]
            
            if songDict.count > 0 {
                let trackName = songDict["name"] as! String
                let trackArtist = songDict["artist"] as! String
                let trackImageURL = songDict["imageURL"] as! String
                let trackPlayURI = songDict["playURI"] as! String
                let trackLink = songDict["trackLink"] as! String
                
                let currentTrack = Track(name: trackName, artist: trackArtist, imageURL: trackImageURL, playURI: trackPlayURI, trackLink: trackLink)
                
                if nowPlaying?.playURI != currentTrack.playURI {
                    
                    nowPlaying = currentTrack
                    
                    // MSG: Could be causing the non update of the album art image in the session when updated by other phone
                    // NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCurrentSong"), object: nil)
                    
                    self.appDelegate.appRemote.playerAPI?.enqueueTrackUri(nowPlaying!.playURI, callback: { (result, error) in
                        self.appDelegate.appRemote.playerAPI?.skip(toNext: { (result, error) in
                            
                        })
                    })
                }
            }
        })
        
        
        // Set Current Queue
        updateFirebaseCurrentQueue()
        // Setup Listener for Current Queue
        let queueRef = groupSessionRef.child("Queue")
        
        _ = queueRef.observe(DataEventType.value, with: { (snapshot) in
            let dict = snapshot.value as? [String : AnyObject] ?? [:]

            if dict.count > 0 {
                let queue = dictionaryToQueue(dict: dict)
                
                currentQueue = queue

                self.queueUpQueue()

                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadQueueTable"), object: nil)

            }
        })
    }
    
    @objc func didTapJoinSesh(_ button: UIButton) {
        performSegue(withIdentifier: "toJoinSessionView", sender: nil)
 
    }
    
    func setupIsSongPlayingListener() {
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        
        let queueRef = groupSessionRef.child("isSongPlaying")
        
        _ = queueRef.observe(DataEventType.value, with: { (snapshot) in
            let isSongPlaying = snapshot.value as? Bool
            
            if isSongPlaying != nil {
                if isSongPlaying! {
                    self.appDelegate.appRemote.playerAPI?.resume(nil)
                    
                } else {
                    self.appDelegate.appRemote.playerAPI?.pause(nil)
                    
                }
                
            }
            
        })
    }
    
    func queueUpQueue() {
        
        for song in currentQueue {
            appDelegate.appRemote.playerAPI?.enqueueTrackUri(song.playURI, callback: { (result, error) in
                
            })
        }
        
        
    }
    
    func updateGroupMembersTable() {
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        
        let groupMembersRef = groupSessionRef.child("Group Members")
        
        _ = groupMembersRef.observe(DataEventType.value, with: { (snapshot) in
            let dict = snapshot.value as? [String : AnyObject] ?? [:]
            
            self.groupMembersDictionary = dict
            
            self.groupSessionTableView.reloadData()
        })
        
        
    }
    
    func updateViewIfSessionActive() {
        
        if groupSessionIsActive || joinedGroupSessionIsActive {
            beginGroupSessionButton.isHidden = true
            joinGroupSessionButton.isHidden = true
            orLabel.isHidden = true
            
            groupMemberTitleLabel.isHidden = false
            topLine.isHidden = false
            groupCodeTitleLabel.isHidden = false
            groupCodeLabel.isHidden = false
            groupSessionTableView.isHidden = false
            
            if groupSessionIsActive {
                leaveOrEndSessionButton.setTitle("End Session", for: .normal)
                leaveOrEndSessionButton.isHidden = false
                
            } else if joinedGroupSessionIsActive {
                leaveOrEndSessionButton.setTitle("Leave Session", for: .normal)
                leaveOrEndSessionButton.isHidden = false
                
            }
            
        } else {
            beginGroupSessionButton.isHidden = false
            joinGroupSessionButton.isHidden = false
            orLabel.isHidden = false
            
            groupMemberTitleLabel.isHidden = true
            topLine.isHidden = true
            groupCodeTitleLabel.isHidden = true
            groupCodeLabel.isHidden = true
            groupSessionTableView.isHidden = true
            leaveOrEndSessionButton.isHidden = true
            
            
        }
        
        
    }
    
    @objc func updateGroupSessionView(_ notification: Notification) {
        groupCodeLabel.text = groupSessionKey
        
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        
        let groupMembersRef = groupSessionRef.child("Group Members")
        
        _ = groupMembersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let dict = snapshot.value as? [String : AnyObject] ?? [:]
            
            self.groupMembersDictionary = dict
            
            self.addSelfToGroupMembers()
            
        })
        
        updateViewIfSessionActive()
        
        updateQueueForJoinedSession()
        
        updateCurrentSongForJoinedSession()
        
        setupIsSongPlayingListenerForJoinedSession()
        
        
        let isSessionEndingRef = groupSessionRef.child("isSessionEnding")
        
        _ = isSessionEndingRef.observe(DataEventType.value, with: { (snapshot) in
            let isSessionEnding = snapshot.value as? Bool
            
            if isSessionEnding == nil || isSessionEnding! {
                joinedGroupSessionIsActive = false
            
                self.updateViewIfSessionActive()
            }
            
        })
        
        
        let updatedFromJoinedSessionRef = groupSessionRef.child("updatedFromJoinedSession")
        
        _ = updatedFromJoinedSessionRef.observe(DataEventType.value, with: { (snapshot) in
            let isUpdatedFromJoinedSession = snapshot.value as? Bool
            
            if isUpdatedFromJoinedSession != nil {
                if isUpdatedFromJoinedSession! {
                    updatedFromJoinedSession = true
                    
                    
                } else {
                    updatedFromJoinedSession = false
                    
                    
                }
            }
            
        })
        
        
    }
    
    
    func updateCurrentSongForJoinedSession() {
        // Setup Listener for Current Song
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        let currentSongRef = groupSessionRef.child("Current Song")
        
        _ = currentSongRef.observe(DataEventType.value, with: { (snapshot) in
            let songDict = snapshot.value as? [String : AnyObject] ?? [:]
            
            if songDict.count > 0 {
                let trackName = songDict["name"] as! String
                let trackArtist = songDict["artist"] as! String
                let trackImageURL = songDict["imageURL"] as! String
                let trackPlayURI = songDict["playURI"] as! String
                let trackLink = songDict["trackLink"] as! String
                
                let currentTrack = Track(name: trackName, artist: trackArtist, imageURL: trackImageURL, playURI: trackPlayURI, trackLink: trackLink)
                
                nowPlaying = currentTrack
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCurrentSong"), object: nil)
                
            }
            })
    }
    
    
    func updateQueueForJoinedSession() {
        // Setup Listener for Current Queue
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        let queueRef = groupSessionRef.child("Queue")
        
        _ = queueRef.observe(DataEventType.value, with: { (snapshot) in
            let dict = snapshot.value as? [String : AnyObject] ?? [:]
            
            if dict.count > 0 {
                let queue = dictionaryToQueue(dict: dict)
                
                currentQueue = queue
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadQueueTable"), object: nil)
                
            }
        })
    }
    
    func setupIsSongPlayingListenerForJoinedSession() {
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        
        let queueRef = groupSessionRef.child("isSongPlaying")
        
        _ = queueRef.observe(DataEventType.value, with: { (snapshot) in
            let isSongPlaying = snapshot.value as? Bool
            
            if isSongPlaying != nil {
                if isSongPlaying! {
                    joinedSessionSongIsPlaying = true
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateIfJoinedSessionSongIsPlaying"), object: nil)
                    
                } else {
                    joinedSessionSongIsPlaying = false
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateIfJoinedSessionSongIsPlaying"), object: nil)
                    
                }
                
            }
            
        })
    }
    
    func addSelfToGroupMembers() {
        // Set yourself as member(#) in Group Members
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        let groupMembersRef = groupSessionRef.child("Group Members")
        
        let groupMember = ["name": currentUsername, "pictureURL": userProfilePictureURL]
        
        var numMembers = 0
        if groupMembersDictionary != nil {
            numMembers = groupMembersDictionary.count
        }
        
        let member = "member" + String(numMembers + 1)
        groupMembersRef.child(member).updateChildValues(groupMember)
        updateGroupMembersTable()
        
        
    }
    
    func removeSelfFromGroupMembers() {
        
        
        let groupMember = ["name": currentUsername, "pictureURL": userProfilePictureURL]
        
        var newMembersDict: [String:AnyObject] = [:]
        var numMembers = 2
        for item in groupMembersDictionary {
            if item.value as! [String : String?] != groupMember {
                if item.key == "member1" {
                    newMembersDict["member1"] = item.value
                    
                    
                } else {
                    let newKey = "member" + String(numMembers)
                    newMembersDict[newKey] = item.value
                    numMembers += 1
                    
                    
                }
            }
        }
        
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        //let groupMembersRef = groupSessionRef.child("Group Members")
        groupSessionRef.updateChildValues(["Group Members" : newMembersDict])
        
    }
    
    @IBAction func leaveOrEndSession(_ sender: Any) {
        if joinedGroupSessionIsActive {
            joinedGroupSessionIsActive = false
            updateViewIfSessionActive()
            removeSelfFromGroupMembers()
            
            currentQueue = []
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchPlayerState"), object: nil)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadQueueTable"), object: nil)
            
            
        } else if groupSessionIsActive {
            groupSessionIsActive = false
            updateViewIfSessionActive()
            endSession()
            
        }
        
    }
    
    func endSession() {
        let groupSessionRef = ref.child("Group Sessions").child(groupSessionKey)
        
        groupSessionRef.updateChildValues(["isSessionEnding" : true])
        
        groupSessionRef.removeValue()
    }
    
    
    
    @IBAction func returnToSession(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func randomKey(length: Int) -> String {
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        
        return String((0..<length).map{ _ in letters.randomElement()! })
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
