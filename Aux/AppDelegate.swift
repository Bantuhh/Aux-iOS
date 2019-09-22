//
//  AppDelegate.swift
//  Aux
//
//  Created by Daniel on 4/9/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit

import Spartan


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        FBSDKApplicationDelegate.sharedInstance()?.application(application, didFinishLaunchingWithOptions: launchOptions)
        
    
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        
        sessionManager.application(app, open: url, options: options)
        
        return handled
    }
    
    
    let SpotifyClientID = "d271f92c3f574142a2f982ed710bd04a"
    let SpotifyRedirectURL = URL(string: "Aux://")!
    
    
    lazy var configuration = SPTConfiguration(
        clientID: SpotifyClientID,
        redirectURL: SpotifyRedirectURL
    )
    
    
    // Spotify Session Manager
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: "https://aux-ios.herokuapp.com/api/token"),
            let tokenRefreshURL = URL(string: "https://aux-ios.herokuapp.com/api/refresh_token") {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""
            
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        
        return manager
    }()
    
    
    // Spotify Remote Player
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        
        return appRemote
    }()
    
    
    // Player state denotes what song is playing, paused, etc
    //fileprivate var lastPlayerState: SPTAppRemotePlayerState?
    
    
//    // OAuth token for Spartan API
//    public var authorizationToken: String?
//    
//    
//    //
//    public var establishedSpotifyConnection = false
    
    
    // Session Initialized, access token acquired
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        
        appRemote.connectionParameters.accessToken = session.accessToken
        
        authorizationToken = session.accessToken
        
        Spartan.authorizationToken = authorizationToken
        
        print("Got token")
        
        appRemote.connect()
        
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
        
        establishedSpotifyConnection = false
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        establishedSpotifyConnection = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: "establishedConnectionToSpotify"), object: nil)
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
        
        print("appRemote: Did establish connection")
        
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        lastPlayerState = nil
        establishedSpotifyConnection = false
        NotificationCenter.default.post(name: Notification.Name(rawValue: "establishedConnectionToSpotify"), object: nil)
        print("appRemote: Did Fail Connection Attempt With Error:", error!)
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        lastPlayerState = nil
        establishedSpotifyConnection = false
        NotificationCenter.default.post(name: Notification.Name(rawValue: "establishedConnectionToSpotify"), object: nil)
        print("appRemote: Did disconnect with error:", error!)
        
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchPlayerState"), object: nil)
        
        debugPrint("Track name: %@", playerState.track.name)
        print("player state changed")
    }
    
    fileprivate func presentAlertController(title: String, message: String, buttonTitle: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        controller.view.layoutIfNeeded()
        controller.addAction(action)
        self.window?.rootViewController?.present(controller, animated: true, completion: nil)
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if (appRemote.isConnected) {
            appRemote.disconnect()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let _ = appRemote.connectionParameters.accessToken {
            appRemote.connect()
        }
        //self.window?.rootViewController?.children[1]
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

