//
//  LobbyViewController.swift
//  ios-project
//
//  Created by Jason Cheung on 2016-11-18.
//  Copyright © 2016 Manjot. All rights reserved.
//

import UIKit
import Firebase
import MapKit


class LobbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var GameIDLabel: UILabel!
    
    @IBOutlet weak var HostSettingsButton: UIButton!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var minusButton: UIButton!
    
    @IBOutlet weak var plusButton: UIButton!
    
    fileprivate var db: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle!   // not observing anything
    fileprivate var gameStartObserver : FIRDatabaseHandle!
    
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    public var gameId : String = ""
    public var hostId : String = ""
    var players = [LobbyUser]()
    var currentUser : LobbyUser?
    
    var mapCoordinate1 : CLLocationCoordinate2D?
    var mapCoordinate2 : CLLocationCoordinate2D?
    
    var gameDuration: Int = 30

    // let lobby : Lobby = Lobby()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self 
        
        configureDatabase()

    }
    
    func startGame(){
        
    }
    
    fileprivate func configureDatabase() {
        // init db
        db = FIRDatabase.database().reference()
        
        // add observer to lobby db
        _refHandle = self.db.child("lobbies").child(gameId).child("players").observe(
            .value,
            with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
                strongSelf.debugShowPlayerJoined(player: snapshot)
                self?.onPlayerListUpdated(playerList: snapshot)
            }
        )
        
        //add observer for gameStart
        gameStartObserver = self.db.child("lobbies").child(gameId).child("gameStart").observe(.value, with: { [weak self] (snapshot) -> Void in
            let value = snapshot.value as! Bool
            print("________________________________________")
            print("gameStart changed; game might of been started by host")
            print("________________________________________")
            if value {
                self?.gameStart()
            }
        })
        
        //username: data.childSnapshot(forPath: "username").value as! String,
        GameIDLabel.text = "Game ID " + gameId
        var tmp = self.db.child("lobbies").child(gameId).observe(.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            //            strongSelf.locationsSnapshot = snapshot
            strongSelf.parseDevicesForHost(devices: snapshot)
        })
        // retrieve values 
        // var lobby = self.db.child("lobbies").child(gameId)
        

    }
    
    
    func parseDevicesForHost(devices: FIRDataSnapshot) {
        
        //grabs the host's device ID from the database
        hostId = devices.childSnapshot(forPath: "hostId").value as! String
        
        if(hostId == deviceId){
            HostSettingsButton.addTarget(self, action: #selector(startMap), for: .touchUpInside)
            HostSettingsButton.backgroundColor = UIColor.clear
        }else{
            HostSettingsButton.isHidden = true
            minusButton.isHidden = true
            plusButton.isHidden = true
        }
        
    }

    
    // This is called when the database players table is updated.
    func onPlayerListUpdated(playerList: FIRDataSnapshot) {
        
        // This looks pretty promising 
        // http://stackoverflow.com/questions/38038990/firebase-converting-snapshot-value-to-objects
        
        for child in playerList.children.allObjects as? [FIRDataSnapshot] ?? [] {

            // Convert to a LobbyUser object to work with
            let user = LobbyUser.MakeFromFIRObject(data: child)
            
            // If the user is us, assign to current user for convenience
            if (user.id == deviceId) {
                currentUser = user
            }
            
            // Update the table datasource
            editOrAddPlayerList(user)
        }
        
        self.tableView.reloadData()

    }
    
    // This updates the table datasource from the database
    func editOrAddPlayerList(_ user : LobbyUser) {
        
        for (index, element) in players.enumerated() {
            // Update
            if (user.id == element.id) {
                players[index] = user
                return;
            }
        }
        
        // Or add
        players.append(user)
    }
    
    func changeReadyStatus(_ torf: Bool) {
        currentUser?.isReady = torf
        updateDatabase(currentUser!)
    }
    
    func updateDatabase(_ user: LobbyUser) {
        self.db.child("lobbies").child(gameId).child("players").child(user.id).setValue(
            ["username": user.username, "role": user.role, "ready": user.isReady]
        )
    }
    
    
    func debugShowPlayerJoined(player: FIRDataSnapshot) {
        
        // create alert
        let alert = UIAlertController(title: "Player joined!", message: "I don't know who though", preferredStyle: UIAlertControllerStyle.alert)
        
        // Add back button
        alert.addAction(UIAlertAction(title: "Back", style: .default))
        
        // Preset alert and play SFX
        //self.present(alert, animated: true, completion: nil)
    }

    deinit {
       // self.db.child("lobbies").child(gameId).removeObserver(withHandle: _refHandle)
    }
    
    
    
    // MARK : - TABLE VIEW
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "lobbyPlayerCell") as! LobbyPlayerCell
        
        cell.lobbyController = self
        cell.lobbyUser = players[indexPath.row]
        
        return cell
    }

    //Start of host map settings stuff
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "mapSegue") {
            let guest = segue.destination as! LobbyMapSelectView
            guest.lobby = self
        } else if (segue.identifier == "showLoadScreen") {
            let guest = segue.destination as! GameStartViewController
            guest.mapPoint1 = self.mapCoordinate1
            guest.mapPoint2 = self.mapCoordinate2
        }
    }
    
    func gameStart() {
        
        self.db.child("lobbies").child(gameId).child("coords").observeSingleEvent(of: .value, with: { (snapshot) in
            let point1 = snapshot.childSnapshot(forPath: "point1").value as? NSDictionary
            let point2 = snapshot.childSnapshot(forPath: "point2").value as? NSDictionary
            print("____ \n In gameStart() setting coordinates \n ____")
            if point1 != nil && point2 != nil {
                let p1Lat = point1?["lat"] as! Double 
                let p1Long = point1?["long"] as! Double
                let p2Lat = point2?["lat"] as! Double
                let p2Long = point2?["long"] as! Double 
                // set client coords to what the DB has
                self.mapCoordinate1 = CLLocationCoordinate2DMake(p1Lat, p1Long)
                self.mapCoordinate2 = CLLocationCoordinate2DMake(p2Lat, p2Long)
            }
 
        })
        performSegue(withIdentifier: "showLoadScreen" , sender: nil)
    }
    
    func startMap(){
        performSegue(withIdentifier: "mapSegue" , sender: nil)
    }
    
    
    @IBAction func startGameListener(_ sender: Any) {
        self.db.child("lobbies").child(gameId).child("coords").updateChildValues([
            "point1" : [
                "lat"   : self.mapCoordinate1?.latitude,
                "long"  : self.mapCoordinate1?.longitude
            ],
            "point2" : [
                "lat"   : self.mapCoordinate2?.latitude,
                "long"  : self.mapCoordinate2?.longitude
            ]
        ])
        self.db.child("lobbies").child(gameId).updateChildValues(["gameStart" : true])
        
        performSegue(withIdentifier: "showLoadScreen" , sender: nil)
    }

    
    //End of host map settings stuff
    
    @IBAction func minusDuration(_ sender: UIButton) {
        if(gameDuration > 1) {
        gameDuration = gameDuration - 1
        durationLabel.text = String(gameDuration) + " mins"
        }
    }
    
    @IBAction func addDuration(_ sender: UIButton) {
        gameDuration = gameDuration + 1
        durationLabel.text = String(gameDuration) + " mins"
    }
}

class LobbyUser {
    var id : String
    var username : String
    var isReady : Bool
    var role : String
    
    init(id: String, username: String, ready: Bool, seeker: String) {
        self.id = id
        self.username = username
        self.isReady = ready
        self.role = seeker
    }
    
    class func MakeFromFIRObject(data: FIRDataSnapshot) -> LobbyUser {
        return LobbyUser(
            id: data.key,
            username: data.childSnapshot(forPath: "username").value as! String,
            ready: data.childSnapshot(forPath: "ready").value as! Bool,
            seeker: data.childSnapshot(forPath: "role").value as! String
        )
    }
    
}

class LobbyPlayerCell: UITableViewCell {
    
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerReadySwitch: UISwitch!
    @IBOutlet weak var playerRoleButton: UIButton!
    
    var lobbyController : LobbyViewController?
    
    var lobbyUser : LobbyUser? {
        didSet {
            playerNameLabel.text = lobbyUser?.username
            playerReadySwitch.isOn = (lobbyUser?.isReady)!
            let role = (lobbyUser?.role.uppercased() == "SEEKER") ? "S" : "H"
            playerRoleButton.setTitle(role, for: .normal)
        
            if (lobbyUser?.id != lobbyController?.deviceId) {
                playerReadySwitch.isEnabled = false
            }
            let roleColor = (lobbyUser?.role.uppercased() == "SEEKER") ? UIColor.darkGray : UIColor.lightGray
            playerRoleButton.backgroundColor = roleColor
            if(lobbyController?.deviceId != lobbyController?.hostId) {
                playerRoleButton.isEnabled = false
            }
        }
    }
    
    @IBAction func playerRoleChange(_ sender: UIButton) {
        if (playerRoleButton.currentTitle == "S") {
            lobbyUser?.role = "hider"
            lobbyController?.updateDatabase(lobbyUser!)
        } else {
            lobbyUser?.role = "seeker"
            lobbyController?.updateDatabase(lobbyUser!)
        }
    }
    
    
    
    @IBAction func onReadyChanged(_ sender: AnyObject) {
        lobbyController?.changeReadyStatus(playerReadySwitch.isOn)
    }
}
