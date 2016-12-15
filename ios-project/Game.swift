//
//  Game.swift
//  ios-project
//
//  Created by Lydia Yu on 2016-10-17.
//  Copyright © 2016 Manjot. All rights reserved.
//
import Foundation
import Firebase

public class Game{
    
    var currentPlayers: [Player] = []
    var gameTime: Int!
    
    var isHost: Bool
    var gameRunning = false
    let gameBackgroundQueue = DispatchQueue(label: "game.queue",
                                            qos: .background,
                                            target: nil)
    
    let notificationCentre = NotificationCenter.default
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    let seeker = "hunter" //because people can't decide what word to use
    
    //Point to profile and game
    var profileSnapshot : FIRDataSnapshot?
    var gameSnapshot : FIRDataSnapshot?
    var lobbySnapshot : FIRDataSnapshot?

    var gametopSnapshot : FIRDataSnapshot?

    var locationsSnapshot: FIRDataSnapshot!
    
    var db: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    //Testing purposes
    var gameId : String = "";
    
    //start game
    init(gameTime: Int, isHost: Bool, gameId: String){
        
        //currentPlayers = players
        self.gameTime = gameTime;
        self.isHost = isHost
        self.gameId = gameId
        print("game id is \(gameId)")
        configureDatabase()
    }
    
    func configureDatabase() {
        //init db
        db = FIRDatabase.database().reference()
        
        // read locations from db

        _refHandle = self.db.child("game").observe(.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else {return}
            strongSelf.locationsSnapshot = snapshot
//            self?.parseLocationsSnapshot(locations: snapshot)
        })

//
//        
//        self.db.child("profile").observe(.value, with: { [weak self] (snapshot) -> Void in
//            guard let strongSelf2 = self else {return}
//            
//            self?.profileSnapshot = snapshot
//        })
//        
//        self.db.child("game").child(gameId).child("players").observe(.value, with: { [weak self] (snapshot) -> Void in
//            guard let strongSelf3 = self else {return}
//            
//            self?.gameSnapshot = snapshot
//        })
//        
//        self.db.child("lobbies").child(gameId).child("players").observe(.value, with: { [weak self] (snapshot) -> Void in
//            guard let strongSelf4 = self else {return}
//            
//            self?.lobbySnapshot = snapshot
//        })
//        
        self.db.child("game").child(gameId).observe(.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf5 = self else {return}
            strongSelf5.gametopSnapshot = snapshot
        })


    }

    // parse locations from db, store in array of tuples
//    func parseLocationsSnapshot(locations: FIRDataSnapshot) {
//        
//        
//        // loop through each device and retrieve device id, lat and long, store in locations array
//        for child in locations.children.allObjects as? [FIRDataSnapshot] ?? [] {
//            guard child.key != "(null" else { return }
//            let childId = child.key
//            let childLat = child.childSnapshot(forPath: "lat").value as! Double
//            let childLong = child.childSnapshot(forPath: "long").value as! Double
//            //print("********* \(childId), \(childLat), \(childLong)")
//
//        }
//        
//    }
    
    func startGame(){
        gameRunning = true
        print("begining game loop")
        gameBackgroundQueue.async {
            self.gameLoop()
        }
    }

    func gameLoop() {
        print("time incremented")
        //TODO: implement function to update game variables
        
        // check if game should end
        let currentPlayerCount = getCurrentPlayersCount()
        let currentHidersCount = getCurrentHidersCount()
        let currentSeekersCount = getCurrentSeekersCount()
        let hostCancelled = checkHostCancelled()
        let outOfTime = checkOutOfTime()
        
        if (currentPlayerCount <= 1 || currentHidersCount == 0 || outOfTime || hostCancelled || currentSeekersCount == 0){

            print("end game conditions met, ending game")
            self.gameRunning = false

        }

        loopGuard()
    }
    
    func loopGuard(){
        print("game running: \(gameRunning)" )
        if (gameRunning){
            sleep(3)
            gameLoop()
        }
        
        print("out of game")
        DispatchQueue.main.async {
            self.quitGame()
        }
    }
    
    
    func getGameTime() -> Int{
        return gameTime
    }
    
    func getCurrentPlayers() -> [Player]{
        return currentPlayers
    }
    
    
    func getCurrentPlayersCount() -> Int{
        //get value from db
        while(gametopSnapshot?.childSnapshot(forPath: "players") == nil){
            print("couldn't get current players count. trying again")
            sleep(2)
        }
        print("current player count: \(Int((gametopSnapshot?.childSnapshot(forPath: "players").childrenCount)!))")
        return Int((gametopSnapshot?.childSnapshot(forPath: "players").childrenCount)!)
//        return 5
    }
    
    func getCurrentHidersCount() -> Int{
        //get value from db
        while(gametopSnapshot?.childSnapshot(forPath: "players") == nil){
            print("couldn't get current hiders count. trying again")
            sleep(1)
        }
        var counter = 0
        for child in gametopSnapshot?.childSnapshot(forPath: "players").children.allObjects as? [FIRDataSnapshot] ?? [] {
            if(child.childSnapshot(forPath: "role").value as! String == "hider") {
                counter += 1
            }
        }
        print("*** hider \(counter)")
        return counter
//        return 5
    }
    
    func getCurrentSeekersCount() -> Int {
        //get value from db
        while(gametopSnapshot?.childSnapshot(forPath: "players") == nil){
            print("couldn't get current seekers count. trying again")
            sleep(1)
        }
        var counter = 0
        for child in gametopSnapshot?.childSnapshot(forPath: "players").children.allObjects as? [FIRDataSnapshot] ?? [] {
            if(child.childSnapshot(forPath: "role").value as! String == "seeker") {
                counter += 1
            }
        }
        print("*** seeker \(counter)")
        return counter;
//        return 5
    }
    
    func checkHostCancelled() -> Bool{
        //return value from db
        while(gametopSnapshot?.value == nil){
            print("couldn't get if host cancelled. trying again")
            sleep(1)
        }
        
        let value = gametopSnapshot?.value as? NSDictionary
        print("host ended value \(value)")
        return value?["hostEnded"] as! Bool
    }
    
    func checkOutOfTime() -> Bool{
        return false
    }
    
    func removeSelfFromGameTable(){
        //disable gps and remove own game entry
        print("turning off gps updates")
        Notifications.postGpsToggled(self, toggle: false)
        sleep(1)
        
//        let deviceId = UIDevice.current.identifierForVendor!.uuidString
//        self.db.child("game").child(gameId).child("players").child(deviceId).removeValue()
    }
    
    func removeLobby() {
        print(db.child("lobbies"))
    }
    
    func showGameEndView(){
        print("posting quit game obs")
        Notifications.postGameEnded(self, gameEnded: true)
    }
    
    func removeObservers(){
        self.db.removeAllObservers() // will removing all affect other parts of the game?
//        self.db.child("game").removeAllObservers()
    }
    
    func quitGame() {
        print("running end game functions")
        removeLobby()
        removeSelfFromGameTable()
        showGameEndView()
//        updateProfile(seekerWin: checkSeekerWin())
    }
    
    //Checks who won game
    func checkSeekerWin() -> Bool{
        
        for child in gameSnapshot?.children.allObjects as? [FIRDataSnapshot] ?? [] {
            if(child.childSnapshot(forPath: "role").value as! String == "hider") {
                return false;
            }
        }
        
        return true;
    }
    
    //Updates the deviceId's profile win/totalPlayed Currently checks for "hunter" cause thats what people have been using
    func updateProfile(seekerWin: Bool){
        
        for child in lobbySnapshot?.children.allObjects as? [FIRDataSnapshot] ?? [] {

            if(child.key == deviceId) {
                let role = child.childSnapshot(forPath: "role").value as! String
                
                var currentTotalPlayed = profileSnapshot?.childSnapshot(forPath: deviceId).childSnapshot(forPath: "totalPlayed").value as! Int;
                
                currentTotalPlayed += 1;
                
                var currentWinCount = profileSnapshot?.childSnapshot(forPath: deviceId).childSnapshot(forPath: "winCount").value as! Int;
                
                //Player is seeker and Seeker wins
                if(role == self.seeker && seekerWin) {
                    currentWinCount += 1;
                }
                
                //Player is hider and Seeker doesn't win
                if(role == "hider" && !seekerWin) {
                    currentWinCount += 1;
                }
                
                //Update profile
                self.db.child("profile").child(deviceId).setValue(
                    ["totalPlayed": currentTotalPlayed, "winCount": currentWinCount, "recentUserName": child.childSnapshot(forPath: "userName")]
                )
            }
        }
        
    }
    
    
    //Unused: Updates all players win/totalPlayed Currently checks for "hunter" cause thats what people have been using
    func updateAllProfiles(seekerWin: Bool){
        
        for child in lobbySnapshot?.children.allObjects as? [FIRDataSnapshot] ?? [] {
            
            let deviceId = child.key
            let role = child.childSnapshot(forPath: "role").value as! String
            
            var currentTotalPlayed = profileSnapshot?.childSnapshot(forPath: deviceId).childSnapshot(forPath: "totalPlayed").value as! Int;
            
            currentTotalPlayed += 1;
            
            var currentWinCount = profileSnapshot?.childSnapshot(forPath: deviceId).childSnapshot(forPath: "winCount").value as! Int;
            
            //Player is seeker and Seeker wins
            if(role == "hunter" && seekerWin) {
                currentWinCount += 1;
            }
            
            //Player is hider and Seeker doesn't win
            if(role == "hider" && !seekerWin) {
                currentWinCount += 1;
            }
            
            //Update profile
            self.db.child("profile").child(deviceId).setValue(
                ["totalPlayed": currentTotalPlayed, "winCount": currentWinCount]
            )
        }
        
    }
    
    
    
    
}
