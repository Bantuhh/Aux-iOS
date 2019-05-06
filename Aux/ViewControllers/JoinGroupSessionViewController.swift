//
//  JoinGroupSessionViewController.swift
//  Aux
//
//  Created by Daniel on 5/3/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import FirebaseDatabase

class JoinGroupSessionViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    var ref: DatabaseReference!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(rgb: 0x252525)
        
        ref = Database.database().reference()
        // Do any additional setup after loading the view.
    }
    
    
    
    @IBAction func joinSessionButtonPressed(_ sender: Any) {
        let groupCode = textField.text
        
        let groupSessionsRef = ref.child("Group Sessions")
        
        groupSessionsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.hasChild(groupCode!) {
                self.presentAlertController(title: "Invalid Group Code", message: "Try again", buttonTitle: "Ok")
                
            } else {
                groupSessionKey = groupCode
                joinedGroupSessionIsActive = true
                // Pause song if playing
                self.appDelegate.appRemote.playerAPI?.pause(nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "updateGroupSessionView"), object: nil)
                self.dismiss(animated: true, completion: nil)
            }
            
            
        })
        
        
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
