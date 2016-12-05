//
//  GameViewController.swift
//  ios-project
//
//  Created by Jason Cheung on 2016-11-04.
//  Copyright © 2016 Manjot. All rights reserved.
//

import UIKit
import MapKit

import Firebase

extension CGSize{
    init(_ width:CGFloat,_ height:CGFloat) {
        self.init(width:width,height:height)
    }
}

class GameViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var NavigationItem: UINavigationItem!
    @IBOutlet weak var MapView: MKMapView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var hiderLabel: UILabel!
    @IBOutlet weak var nearestHiderLabel: UILabel!
    
    let notificationCentre = NotificationCenter.default
    let locationManager = CLLocationManager()
    var locationUpdatedObserver : AnyObject?
    var myPin  = CustomPointAnnotation()
    var temppin2  = CustomPointAnnotation()
    var numberOfPower : Int = 10
    //center pin
    var centerPin = CustomPointAnnotation()
    
    var tempLocation : CLLocationCoordinate2D?
    var mapPoint1 : CLLocationCoordinate2D?
    var mapPoint2 : CLLocationCoordinate2D?
    
    var playerIdToCatch = "unknown"
    var capturable = false

    //set Timer
    var countDownTimer = Timer()
    var timerValue = 1200

    // store the gameId, hardcoded for now
    var gameId = "alex"
    
    var gameEndedObserver : AnyObject?

    var db: FIRDatabaseReference!
    fileprivate var _gameHandle: FIRDatabaseHandle!
    fileprivate var _refHandle: FIRDatabaseHandle!
    fileprivate var _powerHandle: FIRDatabaseHandle!
    fileprivate var _lobdyHandle: FIRDatabaseHandle!
    //var locationsSnapshot: FIRDataSnapshot!
    var locations: [(id: String, lat: Double, long: Double)] = []

    //var gameID = "1"

    
    // SAVES ALL THE DEVICE LOCATIONS
    var pins: [CustomPointAnnotation?] = []
    
    let username = "hello"
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    
    var lat = 0.0
    var long = 0.0
    var lat2 = 0.0
    var long2 = 0.0
    var mapRadius = 0.00486
    var path: MKPolyline = MKPolyline()
    
    // stores power-ups on the map   
    var powerups = [Int: PowerUp]()
    var type : [String] = ["compass","invisable"]
    var firstTime : Bool = true
    var owner : Bool = true
    var lobdyNumber : String = ""
    let defaults = UserDefaults.standard
    var powerPoints = [Int: CLLocationCoordinate2D]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDatabase()
        // TEST MAP
//        var map : Map = Map(topCorner: MKMapPoint(x: 49.247815, y: -123.004096), botCorner: MKMapPoint(x: 49.254675, y: -122.997617), tileSize: 1)
        

        getLobdyNumber()
        
//        if firstTime {
//            if owner {
//                addPowerUp(map: map)
//            }
//        }
        
               var map : Map = Map(topCorner: MKMapPoint(x: (mapPoint1?.latitude)!, y: (mapPoint1?.longitude)!), botCorner: MKMapPoint(x: (mapPoint2?.latitude)!, y: (mapPoint2?.longitude)!), tileSize: 1)

        self.MapView.delegate = self
      
        // Center map on Map coordinates
        MapView.setRegion(convertRectToRegion(rect: map.mapActual), animated: true)
        
        //Disable user interaction
        MapView.isZoomEnabled = false;
        MapView.isScrollEnabled = false;
        MapView.isUserInteractionEnabled = false;
        
        //adding pin onto the center
        let mapPointCoordinate : CLLocationCoordinate2D = MapView.centerCoordinate
        centerPin.coordinate = mapPointCoordinate
        centerPin.playerRole = "centerMap"
        MapView.addAnnotation(centerPin)
        
        
        //TODO: Currently hardcoded, so it must be put in a loop once database is set up
        
        // assign the player to a role, should get this value from lobby somehow
        
        self.myPin.playerRole = "seeker"

        self.myPin.playerId   = self.deviceId
        
        
        // DEBUG TEMPPIN
        self.temppin2.playerId = "TESTPIN"
        self.temppin2.playerRole = "hider"
        
        locationUpdatedObserver = notificationCentre.addObserver(forName: NSNotification.Name(rawValue: Notifications.LocationUpdated),
                                                                 object: nil,
                                                                 queue: nil)
        {
            (note) in
            let location = Notifications.getLocation(note)
            
            if let location = location
            {
                self.lat = location.coordinate.latitude
                self.long = location.coordinate.longitude
                
                // POSTING LAT LONG TO MAP
                self.tempLocation  = CLLocationCoordinate2D(latitude: self.lat, longitude: self.long)
                
                
                // POSTING TO DB
                self.db.child("game").child(self.gameId).child("players").child(self.deviceId).setValue([
                    "lat": self.lat, "long": self.long, "role":self.myPin.playerRole])
                
                // CHANGE ROLE LABEL FOR UI
                // SHOW CORRECT BUTTON UI
                if(self.myPin.playerRole == "seeker"){
                    self.roleLabel.text = "You are Seeking!"
                    self.captureButton.isHidden = false
                    self.hiderLabel.isHidden = true
                    self.nearestHiderLabel.isHidden = false
                }else{
                    self.roleLabel.text = "You are Hiding!"
                    self.captureButton.isHidden = true
                    self.hiderLabel.isHidden = false
                    self.nearestHiderLabel.isHidden = true
                }
                
                // DEBUG PIN
                if(self.lat2 == 0.0){
                    // set second pin somewhere above and to left of center pin
                    self.lat2 = location.coordinate.latitude
                    self.long2 = location.coordinate.longitude - 0.0015
                }

                // move the pin slowly to the right
                self.long2 = self.long2 + 0.0001

                // display second pin
                self.MapView.removeAnnotation(self.temppin2)
                self.tempLocation  = CLLocationCoordinate2D(latitude: self.lat2, longitude: self.long2)
                self.temppin2.coordinate = self.tempLocation!

                
                // POSTING TO DB
                self.db.child("game").child(self.gameId).child("players").child(self.temppin2.playerId).setValue([
                    "lat": self.lat2, "long": self.long2, "role":self.temppin2.playerRole])

//                self.configurePowerUpDatabase()
//                
//                
//                self.searchPowerUp()
            }
        }
        
        
         //this sends the request to start fetching the location
        Notifications.postGpsToggled(self, toggle: true)
        
        // add observer for end game signal
        addGameEndObs()

    }
    
    // get lobdy number
    func getLobdyNumber(){
        lobdyNumber = defaults.string(forKey: "gameId")!
        if(defaults.string(forKey: "authorization") == "owner"){
            owner = true
            print("==================== owner ===================")
        }else{
            owner = false
        }
    
    }
    
    func countDown(){
        timerValue = timerValue - 1
        if timerValue > 0 {
            NavigationItem.title = "Time: " + timeFormatted(totalSeconds: timerValue)
        }else{
            print("Timer countdown to 0")
        }
    }
    
    //Format time
    func timeFormatted(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // remove the pin(power up), when it is used or collected by a player, from the map
    func activePowerUp(id: Int) {
        _ = try! HiderInvisibility(id: id, duration: 30, isActive: false)
        self.MapView.removeAnnotation(powerups[id] as! MKAnnotation)
        powerups.removeValue(forKey: id)
        powerPoints.removeValue(forKey: id)
        self.db.child("powerup").child(lobdyNumber).removeValue()
        for i in powerPoints{
            self.db.child("powerup").child(lobdyNumber).child(String(i.key)).setValue([
                "lat": i.value.latitude, "long": i.value.longitude])
        }
        
    }
    
    func configureDatabase() {
        //init db
        db = FIRDatabase.database().reference()
        
        // read locations from db
        _refHandle = self.db.child("game").child(gameId).child("players").observe(.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.parseLocationsSnapshot(locations: snapshot)
        })
    }
    

    func configurePowerUpDatabase() {
        //init db
        db = FIRDatabase.database().reference()
        
        // read locations for power up from db
        _powerHandle = self.db.child("powerup").child(lobdyNumber).observe(.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.parsePowerUpSnapshot(locations: snapshot)
        })
        
        
    }
    
    
    // parse power up locations from db, store in array of tuples
    func parsePowerUpSnapshot(locations: FIRDataSnapshot) {
        // empty the array
        // REMOVING ALL THE PINS FROM THE DATABASE FIRST SO WE CAN UPDATE IT
        for index in self.powerups {
            self.MapView.removeAnnotation(powerups[index.key] as! MKAnnotation)
            print("remove " + String(index.key))
        }
        self.powerups.removeAll()
        self.powerPoints.removeAll()
        // loop through each device and retrieve device id, lat and long, store in locations array
        for child in locations.children.allObjects as? [FIRDataSnapshot] ?? [] {
            guard child.key != "(null" else { return }
            let childId = child.key
            let childLat = child.childSnapshot(forPath: "lat").value as! Double
            let childLong = child.childSnapshot(forPath: "long").value as! Double
            let childtype = child.childSnapshot(forPath: "type").value as! String
            var temp = CLLocationCoordinate2D()
            temp.latitude = childLat
            temp.longitude = childLong
            
            
            if(childtype == type[1]){
                let invsablePower = try! HiderInvisibility(id: Int(childId)!,duration: 30,isActive: true)
                //Add the power up to the map
                invsablePower.coordinate = temp
                //store the id and locations of the PowerUps, it is easier to find out which power up on the map is to be used or removed
                self.MapView.addAnnotation(invsablePower)
                print("add invisale " + childId)
                self.powerups[Int(childId)!] = invsablePower
                self.powerPoints[Int(childId)!] = invsablePower.coordinate
            }else{
                
                let compassPower = try! SeekerCompass(id: Int(childId)!,duration: 30,isActive: true)
                //Add the power up to the map
                compassPower.coordinate = temp
                //store the id and locations of the PowerUps, it is easier to find out which power up on the map is to be used or removed
                self.MapView.addAnnotation(compassPower)
                print("add compass " + childId)
                self.powerups[Int(childId)!] = compassPower
                self.powerPoints[Int(childId)!] = compassPower.coordinate
            }
            
        }
        
        //print("***** updated locations array ****** \(self.locations)")
        
        // call functions once array of locations is updated
        
    }
    
    func searchPowerUp(){
        if(pins.count > 0){
            let userLoc = CLLocation(latitude: temppin2.coordinate.latitude , longitude: temppin2.coordinate.longitude)
            if (powerups.count == 0){
                return
            }
            for i in powerPoints{
                if(userLoc.coordinate.longitude - (i.value.longitude) > -0.004 &&
                   userLoc.coordinate.longitude - (i.value.longitude) < 0.004 &&
                   userLoc.coordinate.latitude - (i.value.latitude) > -0.004 &&
                   userLoc.coordinate.latitude - (i.value.latitude) < 0.004){
                    activePowerUp(id: i.key)
                }
            }
        }
    }
    
    // Get all player locations from game > gameId > players
    func parseLocationsSnapshot(locations: FIRDataSnapshot) {
        // empty the array
        self.locations.removeAll()
        
        // REMOVING ALL THE PINS FROM THE DATABASE FIRST SO WE CAN UPDATE IT
        for index in pins {
            self.MapView.removeAnnotation(index!)
        }
        
        // empty pins array
        pins.removeAll()
        
        
        // loop through each device and retrieve device id, lat and long, store in locations array
        for child in locations.children.allObjects as? [FIRDataSnapshot] ?? [] {
            guard child.key != "(null" else { return }
            let childId = child.key
            var childLat = 0.0
            var childLong = 0.0
            if (child.childSnapshot(forPath: "lat").value as? Double != nil){
                childLat = child.childSnapshot(forPath: "lat").value as! Double
            }
            
            if (child.childSnapshot(forPath: "long").value as? Double != nil){
                childLong = child.childSnapshot(forPath: "long").value as! Double
            }
            
            var playerRole = " "
            
            if(child.childSnapshot(forPath: "role").value as? String != nil){
                playerRole = child.childSnapshot(forPath: "role").value as! String
            }
            
            self.locations += [(id: childId, lat: childLat, long: childLong )]
            
            // ADDING OTHER DEVICES FROM DB TO THE MAP AND SAVING THAT LOCATION INTO GLOBAL VAR PINS
            var tempLocation : CLLocationCoordinate2D
            tempLocation  = CLLocationCoordinate2D(latitude: childLat, longitude: childLong)
            
            if childId == deviceId { // if the id is yourself
                self.myPin.coordinate = tempLocation
                self.myPin.playerRole = playerRole
                self.myPin.playerId   = childId
                pins.append(self.myPin)
                self.MapView.addAnnotation(self.myPin)
            }else{
                
                let otherPin  = CustomPointAnnotation()
                otherPin.playerId   = childId
                otherPin.coordinate = tempLocation
                otherPin.playerRole = playerRole
                
                pins.append(otherPin)
                
                //DEBUG
                if(self.temppin2.playerId == childId){
                    self.temppin2.playerRole = playerRole
                }
                
                self.MapView.addAnnotation(otherPin)
            }
        }
        pointToNearestPin()
        
        //print("***** updated locations array ****** \(self.locations)")
        
        // call functions once array of locations is updated
        
    }

    func pointToNearestPin(){
        
        if(pins.count > 0){
            // CLLocation of user pin
            let userLoc = CLLocation(latitude: myPin.coordinate.latitude, longitude: myPin.coordinate.longitude)
            
            // pin of current smallest distance
            var smallestDistancePin = CustomPointAnnotation()
            var smallestDistance = 10000000.0
            var nearestHider = 10000000.0
            for pin in pins{
                
                // skip if pin is yourself
                if(pin?.playerId == self.deviceId){
                    continue
                }
                
                // create a CLLocation for each pin
                let loc = CLLocation(latitude: (pin?.coordinate.latitude)!, longitude: (pin?.coordinate.longitude)!)
                
                // get the distance between pins
                let distance = userLoc.distance(from: loc)
                
                if(smallestDistance > distance){
                    
                    smallestDistance = distance
                    
                    // if self is "seeker" and smallest pin is "hider"
                    // change hider to seeker
                    if(self.myPin.playerRole == "seeker"
                        && pin?.playerRole == "hider"
                        && smallestDistance < 10)
                    {
                        captureButton.isEnabled = true
                        capturable = true
                        playerIdToCatch = (pin?.playerId)!
                    }else{
                        playerIdToCatch = "unknown"
                        capturable = false
                        captureButton.isEnabled = false
                    }
                    
                    // assign pin to smallest distance pin
                    smallestDistancePin = pin!
                }
                
                // get the nearest hider if you're a seeker
                if(self.myPin.playerRole == "seeker" && pin?.playerRole == "hider"){
                    if(nearestHider > distance){
                        nearestHider = distance
                    }
                }
            }
            if(nearestHider == 10000000.0){
                nearestHiderLabel.text = "No hiders left"
            }else{
                let str = String(format: "%.2f", arguments: [nearestHider])
                nearestHiderLabel.text = "Nearest Hider: " + str + "m"
            }
            
            
            // point arrow to smallest distance pin
            self.UnoDirections(pointA: self.myPin, pointB: smallestDistancePin);
        }
    }
    
    @IBAction func capturePlayer(_ sender: Any) {
        if(capturable == true){
            for pin in pins{
                if(pin?.playerId == playerIdToCatch){
                    let lat = (pin?.coordinate.latitude)! as Double
                    let long = (pin?.coordinate.longitude)! as Double
                    
                    // POSTING TO DB
                    self.db.child("game").child(self.gameId).child("players").child(playerIdToCatch).setValue([
                        "lat": lat, "long": long, "role": "seeker"])
                }
            }
        }
    }
    
    deinit {
        self.db.child("locations").removeObserver(withHandle: _refHandle)
    }
    
    func UnoDirections(pointA: MKPointAnnotation, pointB: MKPointAnnotation){

        var coordinates = [CLLocationCoordinate2D]()
        
        let endLat = pointB.coordinate.latitude
        let endLong = pointB.coordinate.longitude
        let startLat = pointA.coordinate.latitude
        let startLong = pointA.coordinate.longitude
        
        let endPointLat = startLat - (startLat - endLat)/5
        let endPointLong = startLong - (startLong - endLong)/5
        
        coordinates += [CLLocationCoordinate2D(latitude: startLat, longitude: startLong)]
        coordinates += [CLLocationCoordinate2D(latitude: endPointLat, longitude: endPointLong)]
        
        // remove previous "arrow"
        self.MapView.remove(path)
        
        // update arrow
        path = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        self.MapView.add(path)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay.isKind(of: MKPolyline.self){
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 1
            return polylineRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of: MKUserLocation.self) else {
            
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView!.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        
        
        if annotation is PowerUp{
            let customAnnotation = annotation as! PowerUp
            annotationView!.image = customAnnotation.icon
            
        }else if annotation is CustomPointAnnotation{
            let customAnnotation = annotation as! CustomPointAnnotation
            
            if customAnnotation.playerRole == "hider" {
                annotationView!.image = self.resizeImage(image: UIImage(named: "team_red")!, targetSize: CGSize(30, 30))
            } else if customAnnotation.playerRole == "seeker" {
                annotationView!.image = self.resizeImage(image: UIImage(named: "team_blue")!, targetSize: CGSize(30, 30))
            } else if customAnnotation.playerRole == "centerMap"{
                annotationView!.image = self.resizeImage(image: UIImage(named: "Pokeball")!, targetSize: CGSize(30, 30))
            }
        }
 
        return annotationView
        
    }
    
    //Resize pin image
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        

        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func postLocationToMap(templocation: CLLocationCoordinate2D) {
        
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "gameState") {
            let svc = segue.destination as! GameStateViewController;
            svc.toPass = gameId
        }
    }
    
    func convertRectToRegion(rect: MKMapRect) -> MKCoordinateRegion {
        // find center
        return MKCoordinateRegionMake(
            CLLocationCoordinate2DMake(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height/2),
            MKCoordinateSpan(latitudeDelta: rect.size.width, longitudeDelta: rect.size.height)
        )
    }
    
    func random() -> Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
    func randomIn(_ min: Double,_ max: Double) -> Double {
        return random() * (max - min ) + min
    }
    
    func changeRole(roles: FIRDataSnapshot){
        let getRole = roles.childSnapshot(forPath: "role").value as? String
        
        if (getRole == "hider"){
            
        }
    }
    

    // FOR TESTING GAME CLASS
    override func viewDidAppear(_ animated: Bool) {
        startGame()
        
        // game ended, go to game end view
//        performSegue(withIdentifier: "showGameEndView" , sender: nil)
    }
    
    func startGame(){
        let player1 = Player("player1")
        let player2 = Player("player2")
        
        let game = Game(gameTime: 2, isHost: true)
        game.startGame()
//        performSegue(withIdentifier: "showGameEndView" , sender: nil)
    }
    
    func addGameEndObs(){
        gameEndedObserver = notificationCentre.addObserver(forName: NSNotification.Name(rawValue: Notifications.GameEnded),
                                                           object: nil,
                                                           queue: nil)
        {
            (note) in
            let gameEnded = Notifications.getGameEnded(note)
            print("game ended: \(gameEnded), segue into game end view")
            self.segueToGameEndView()
        }
    }
    
    func segueToGameEndView(){
        performSegue(withIdentifier: "showGameEndView" , sender: nil)
    }
    // END TESTING GAME CLASS

    func addPowerUp(map: Map){
        //1st power up
        //Get x and y coordinates of corners of the map
        let rx = map.bottomRightPoint.x
        let lx = map.topLeftPoint.x
        let ry = map.bottomRightPoint.y
        let ly = map.topLeftPoint.y
        db = FIRDatabase.database().reference()
        
        for i in 1 ... numberOfPower{
            //Generate random coordinate for the powerup
            let lat  = self.randomIn(lx,rx)
            let long  = self.randomIn(ly,ry)
            let diceRoll = Int(arc4random_uniform(2))
            if(diceRoll == 0){
                self.db.child("powerup").child(lobdyNumber).child(String(i)).setValue([
                    "lat": lat, "long": long, "type": type[0]])

            
            }else{
                self.db.child("powerup").child(lobdyNumber).child(String(i)).setValue([
                    "lat": lat, "long": long, "type": type[1]])

            }
        }
        firstTime = false
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
