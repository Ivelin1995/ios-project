//
//  MainMenuViewController.swift
//  ios-project
//
//  Created by Jason Cheung on 2016-11-18.
//  Copyright © 2016 Manjot. All rights reserved.
//

import UIKit
import Firebase

class MainMenuViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var gameIdTextField: UITextField!
    
    fileprivate var db: FIRDatabaseReference!
    // fileprivate var _refHandvar FIRDatabaseHandle!   // not observing anything
    
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    var targetGameId: String = ""
    let defaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDatabase()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCreateClick(_ sender: AnyObject) {
        let gameId = gameIdTextField.text
        
        // Create lobby if code is not in use
        self.db.child("lobbies").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.hasChild(gameId!){
                
                print("true rooms exist")
                self.showError(message: "This lobby code is already in use!")
                
            }else{
                
                print("false room doesn't exist")
                self.createRoom(gameId: gameId!)
 
            }
            
            
        })
        
    }

    @IBAction func onJoinClick(_ sender: AnyObject) {
        let gameId = gameIdTextField.text
        
        // Create lobby if code is not in use
        self.db.child("lobbies").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.hasChild(gameId!){
                
                print("true rooms exist")
                self.joinRoom(gameId: gameId!)
                
            }else{
                
                print("false room doesn't exist")
                self.showError(message: "This game does not exist.")
            }
            
            
        })
    }
    
    fileprivate func createRoom(gameId : String) {
        
        /* can't nest arrays in data
         let data = [
         "hostId": deviceId,
         "players": [
         "deviceId": deviceId,
         "ready": false,
         "role": "hutner"
         ]
         ] as [String : Any] */
        
        
        let username = usernameTextField.text!
        
        self.targetGameId = gameId;
        defaults.setValue(gameId, forKey: "gameId")
        defaults.setValue( "owner", forKey: "authorization")
        defaults.synchronize()
        self.db.child("lobbies").child(gameId).setValue(["hostId": deviceId, "gameStart": false])
        self.db.child("lobbies").child(gameId).child("players").child(deviceId).setValue(["ready": false, "role": "hunter", "username": username])
        self.db.child("lobbies").child(gameId).child("coords").setValue(["point1": ["lat" : 0, "long" : 0], "point2" : ["lat" : 0, "long" : 0]])
        
        performSegue(withIdentifier: "LobbySegue", sender: self)
    }
    
    fileprivate func joinRoom(gameId : String) {
        
        let username = usernameTextField.text!

        self.targetGameId = gameId;
        defaults.setValue(gameId, forKey: "gameId")
        defaults.setValue( "member", forKey: "authorization")
        defaults.synchronize()
        self.db.child("lobbies").child(gameId).child("players").child(deviceId).setValue(["ready": false, "role": "hunter", "username": username])
        
        performSegue(withIdentifier: "LobbySegue", sender: self)
    }
    
    fileprivate func showError(message : String) {
        // TODO
    }
    
    fileprivate func configureDatabase() {
        // init db
        db = FIRDatabase.database().reference()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LobbySegue" {
            if let destination = segue.destination as? LobbyViewController {
                destination.gameId = self.targetGameId
            }
        }
    }
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
}
