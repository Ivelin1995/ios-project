//
//  GameEndViewController.swift
//  ios-project
//
//  Created by Gary Szeto on 2016-12-02.
//  Copyright © 2016 Manjot. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class GameEndViewController: UIViewController {
    
    @IBOutlet weak var winLabel: UILabel!
    @IBOutlet weak var lossLabel: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    
    fileprivate var db: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle!   // not observing anything
    
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        db = FIRDatabase.database().reference()
        
        // read locations from db
//        _refHandle = self.db.child("profile").child(deviceId).observe(.value, with: { [weak self] (snapshot) -> Void in


//            let value = snapshot.value as? NSDictionary	
//            let recentUserName = value?["recentUserName"] as? String ?? ""
//            let totPlayed = value?["totalPlayed"] as? String ?? ""
//            let winCount = value?["winCount"] as? String ?? ""
            
//            self?.topLabel.text=(recentUserName)
            
            //call either wonGame or lostGame depending on outcome of game
//            self?.wonGame()
            
//            let losses = Int(totPlayed)!-Int(winCount)!
            
//            self?.lossLabel.text=String(losses)
//            self?.winLabel.text=String(winCount)
            
            //kill instance of game if not dead already
//        })
        topLabel.text = "Game Over!"
    }
    
    func wonGame(){
        // increase gamesplayed and won
//        topLabel.text=(topLabel.text! + ", You Won!")
    }
    func lostGame(){
        //increase gamesplayed
//        topLabel.text=(topLabel.text! + ", You Lost!")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ReturnButtonController(_ sender: Any) {
        
    }
    
}
