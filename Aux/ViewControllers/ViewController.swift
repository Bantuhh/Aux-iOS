//
//  ViewController.swift
//  Aux
//
//  Created by Daniel on 4/9/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import FirebaseDatabase

class ViewController: UIViewController{

    @IBOutlet weak var FBButton: UIButton!
    
    var name: String?
    var email: String?
    var id: String?
    var profilePicture: UIImage?
    var profilePictureUrl: String?
    
    var ref: DatabaseReference!
    
    @IBOutlet weak var signoutButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgb: 0x252525)
        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        
        if FBSDKAccessToken.currentAccessTokenIsActive() {
            // User is logged in, use 'accessToken' here.
            // Go to next view
            signoutButton.isEnabled = true
        } else {
            signoutButton.isEnabled = false
        }
    }
    
    @IBAction func FBLoginButton(_ sender: Any) {
        
        if FBSDKAccessToken.currentAccessTokenIsActive() {
            
            let userID = Auth.auth().currentUser?.uid
            ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                currentUsername = value?["name"] as? String ?? ""
                userProfilePictureURL = value?["profilePictureUrl"] as? String ?? "none"
                
                // ...
            }) { (error) in
                print(error.localizedDescription)
            }
            
            
            // User is logged in, use 'accessToken' here.
            // Go to next view
            performSegue(withIdentifier: "toMusicLogin", sender: nil)

        } else {

            let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        
            fbLoginManager.loginBehavior = .native
            
            fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self)
            { (result, error) -> Void in
                if (error == nil)
                {
                    guard FBSDKAccessToken.current() != nil else {
                        print("Failed to get access token")
                        return
                    }
                    
                    if result!.isCancelled {
                        return
                    }
                    
                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    
                    Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        
                        print("User signed in with Auth")
                        
                        self.fetchFBUser()
                        
                        self.performSegue(withIdentifier: "toMusicLogin", sender: nil)
                    }
                    
                } else {
                    
                    print("Failed to login: !!")
                    return
                }
            }
        }
    }
    
    func fetchFBUser() {
        let graphRequestConnection = FBSDKGraphRequestConnection()
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, email, picture.type(large)"])
        graphRequest!.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
            } else {
                print("Successfully fetched user: \(result)")
                
                let values: [String:AnyObject] = result as! [String : AnyObject]
                
                self.id = values["id"]! as? String
                self.name = values["name"]! as? String
                self.email = values["email"]! as? String
                let picture = values["picture"] as! [String : Any?]
                let data = picture["data"] as! [String : Any?]
                
                guard let profilePictureUrl = data["url"]!, let url = URL(string: profilePictureUrl as! String) else {return}
                self.profilePictureUrl = profilePictureUrl as? String
                
                userProfilePictureURL = profilePictureUrl as? String
                currentUsername = self.name
                
                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, err) in
                    if let err = err {
                        print(err)
                        return
                    }
                    guard let data = data else {return}
                    self.profilePicture = UIImage(data: data)
                    print("Saving user into database...")
                    self.saveUserIntoFirebase()
                }).resume()
                
            }
        })
    }
    
    func saveUserIntoFirebase() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let uploadData = self.profilePicture!.jpegData(compressionQuality: 0.3) else { return }
        
        Storage.storage().reference().child("profileImages").child(uid).putData(uploadData, metadata: nil)
          { (metadata, err) in
            if let error = err {
                print(error)
                return
            }
            print("Successfully saved image into storage.")
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let dictionaryValues = ["name": self.name,
                                    "email": self.email,
                                    "profilePictureUrl": self.profilePictureUrl]
            
            let values = [uid: dictionaryValues]
            
            self.ref.child("users").updateChildValues(values, withCompletionBlock: { (err,
              reference) in
                if let err = err {
                    print(err)
                    return
                }
                print("Successfully saved user into Firebase database.")
            })
            
        }
        
    }
    
    @IBAction func signout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            FBSDKLoginManager().logOut()
            print("User Signed out")
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

