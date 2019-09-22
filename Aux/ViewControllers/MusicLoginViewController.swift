//
//  MusicLoginViewController.swift
//  Aux
//
//  Created by Daniel on 4/21/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit

class MusicLoginViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
 
    var numConnectAttempts: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgb: 0x252525)
        
        view.addSubview(connectLabel)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        view.addSubview(closeSpotifyCaption)
        
        let constant: CGFloat = 16.0
        
        numConnectAttempts = 0 // If num attempts = 2, then make caption to close spotify and try again
        
        connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        disconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        disconnectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        connectLabel.centerXAnchor.constraint(equalTo: connectButton.centerXAnchor).isActive = true
        connectLabel.bottomAnchor.constraint(equalTo: connectButton.topAnchor, constant: -constant).isActive = true
        
        closeSpotifyCaption.centerXAnchor.constraint(equalTo: connectButton.centerXAnchor).isActive = true
        closeSpotifyCaption.bottomAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: constant*2.5).isActive = true
        
        connectButton.sizeToFit()
        disconnectButton.sizeToFit()
        
        connectButton.addTarget(self, action: #selector(didTapConnect(_:)), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(didTapDisconnect(_:)), for: .touchUpInside)
        
        updateViewBasedOnConnected()
        
        NotificationCenter.default.addObserver(self, selector: #selector(establishedConnectionToSpotify(_:)), name: Notification.Name(rawValue: "establishedConnectionToSpotify"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    func updateViewBasedOnConnected() {
        DispatchQueue.main.async {
            if (establishedSpotifyConnection) {
                self.connectButton.isHidden = true
                self.disconnectButton.isHidden = false
                self.connectLabel.isHidden = true
                self.closeSpotifyCaption.isHidden = true

            } else {
                self.disconnectButton.isHidden = true
                self.connectButton.isHidden = false
                self.connectLabel.isHidden = false
                self.closeSpotifyCaption.isHidden = true
                
            }
        }
    }
    
    fileprivate lazy var connectLabel: UILabel = {
        let label = UILabel()
        label.text = "Connect your Spotify account"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    fileprivate lazy var closeSpotifyCaption: UILabel = {
        let label = UILabel()
        label.text = "Close your Spotify app and try again."
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    fileprivate lazy var connectButton = ConnectButton(title: "CONNECT")
    fileprivate lazy var disconnectButton = ConnectButton(title: "DISCONNECT")
    
    @objc func didTapDisconnect(_ button: UIButton) {
        if (appDelegate.appRemote.isConnected) {
            appDelegate.appRemote.disconnect()
        }
    }
    
    @objc func didTapConnect(_ button: UIButton) {
        let scope: SPTScope = [.appRemoteControl, .playlistReadPrivate, .userLibraryRead, .streaming]
        
        appDelegate.sessionManager.initiateSession(with: scope, options: .clientOnly)
        
        numConnectAttempts += 1
        
        if (numConnectAttempts >= 2) {
            self.closeSpotifyCaption.isHidden = false
            
        }
        
        //updateViewBasedOnConnected()
    }
    
    @objc func establishedConnectionToSpotify(_ notification: Notification) {
        
        updateViewBasedOnConnected()
        
        
    }
    
    @IBAction func okButton(_ sender: Any) {
        if !establishedSpotifyConnection {
            presentAlertController(title: "Not Connected to Spotify", message: "Please ensure you are connected before continuing.", buttonTitle: "Ok")
        } else {
            performSegue(withIdentifier: "toTabBar", sender: nil)
        }
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
