//
//  GameStateViewController.swift
//  ios-project
//
//  Created by Lydia Yu on 2016-12-03.
//  Copyright © 2016 Manjot. All rights reserved.
//

import UIKit
import Firebase

class GameStateViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var hiderValue: UILabel!
    @IBOutlet weak var seekerValue: UILabel!
    var db: FIRDatabaseReference!
    var Players: Array< String > = Array < String >()
    fileprivate var _refHandle: FIRDatabaseHandle!
    fileprivate var _refHandlePlayer: FIRDatabaseHandle!
    fileprivate var _refHandleProfile: FIRDatabaseHandle!
    var hostQuitObserver : AnyObject?
    let notificationCentre = NotificationCenter.default
    //for testing
    var seekersCount = 0
    var hidersCount = 0
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    //for testing
    //let deviceId = "262E2058-981A-415F-950F-00517F4BF312"
    var playerIsHost: Bool = false
    var countPlayTime: Int = 0
    var updateEvent: Bool = false
    var toPass: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureDatabase()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func configureDatabase() {
        // init db
        db = FIRDatabase.database().reference()
        let gameId = toPass!
        // add observer to game db, get player roles and host deviceId
        _refHandle = self.db.child("game").child(gameId).child("players").observe(.value,
            with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.showHiders(player: snapshot)
            })
        _refHandlePlayer = self.db.child("game").child(gameId).child("hostId").observe(.value,
            with: { [weak self] (snapshot) -> Void in
            let value = snapshot.value as! String
            self?.getPlayerRole(playerRole: value)
            })
    }
    
    //get players info from db.game table and show in the table view
    func showHiders(player: FIRDataSnapshot) {
        for child in player.children.allObjects as? [FIRDataSnapshot] ?? [] {
            Players.append(child.childSnapshot(forPath: "role").value as! String)
        }
        
        for role in Players{
            if(role == "seeker"){
                seekersCount += 1
            }else{
                hidersCount += 1
            }
        }
        
        seekerValue.text = String(seekersCount)
        hiderValue.text = String(hidersCount)
        print("---------# of seekers and hiders---------")
        print("seeker")
        print(seekersCount)
        print("hider")
        print(hidersCount)
        print("-----------------------------------------")
        self.tableView.reloadData()
        
    }
    
    //check if player is host and set different text for button
    func getPlayerRole(playerRole: String) {
        print("-----------------device id---------------")
        print(playerRole)
        print("-----------------------------------------")
        if(deviceId == playerRole){
            playerIsHost = true
            quitButton.setTitle("End Game",for: .normal)
        }
    }
    

    @IBAction func quitGame(_ sender: AnyObject) {
        let gameId = toPass!
        //host end the game
        if(quitButton.titleLabel!.text == "End Game"){
            self.db.child("game").child(gameId).child("hostEnded").setValue(true)
        //play quit the game
        }else{
            updateEvent = true
            self.db.child("game").child(gameId).child("players").child(deviceId).removeValue()
            addTotalPlayed()
        }
    }
    
    //get totalPlayed data from profile and add 1
    func addTotalPlayed() {
        _refHandleProfile = self.db.child("profile").child(deviceId).child("totalPlayed").observe(.value,
          with: { [weak self] (snapshot) -> Void in
          let value = Int(snapshot.value as! String)! + 1
          self?.updateData(data: value)
        })
        //updateData(data: timePlayed)
    }

    //update totalPlayed in profile table
    fileprivate func updateData(data: Int){
        if(updateEvent){
            self.db.child("profile").child(deviceId).child("totalPlayed").setValue(String(data))
            updateEvent = false
        }
    }
}
