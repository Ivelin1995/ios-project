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

    @IBOutlet weak var MapView: MKMapView!
    
    let notificationCentre = NotificationCenter.default
    let locationManager = CLLocationManager()
    var locationUpdatedObserver : AnyObject?
    var temppin  = CustomPointAnnotation()
    var temppin2  = CustomPointAnnotation()
    var numberOfPower : Int = 10
    //center pin
    var centerPin = CustomPointAnnotation()
    
    var tempLocation : CLLocationCoordinate2D?
//    var map : Map?
    
    
    var db: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle!
//    var locationsSnapshot: FIRDataSnapshot!
    var locations: [(id: String, lat: Double, long: Double)] = []
    
    
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
    var powerUp = [Int: CLLocationCoordinate2D]()

    
    var map : Map = Map(topCorner: MKMapPoint(x: 49.247815, y: -123.004096), botCorner: MKMapPoint(x: 49.254675, y: -122.997617), tileSize: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        configureDatabase()

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
        
        //1st power up
        //Get x and y coordinates of corners of the map
        let rx = self.map.bottomRightPoint.x
        let lx = self.map.topLeftPoint.x
        let ry = self.map.bottomRightPoint.y
        let ly = self.map.topLeftPoint.y
        
        for i in 0 ... numberOfPower{
            //Generate random coordinate for the powerup
            let r  = self.randomIn(lx,rx)
            let l  = self.randomIn(ly,ry)
            self.tempLocation  = CLLocationCoordinate2D(latitude: r, longitude: l)
            
            let diceRoll = Int(arc4random_uniform(2))
            if(diceRoll == 0){
                let invsablePower = try! HiderInvisibility(id: i,duration: 30,isActive: true)
                //Add the power up to the map
                invsablePower.coordinate = self.tempLocation!
                self.MapView.addAnnotation(invsablePower)

            
                //store the id and locations of the PowerUps, it is easier to find out which power up on the map is to be used or removed
                powerUp[i] = invsablePower.coordinate
                
            }else{
            
                let compassPower = try! SeekerCompass(id: i,duration: 30,isActive: true)
                //Add the power up to the map
                compassPower.coordinate = self.tempLocation!
                self.MapView.addAnnotation(compassPower)
                
                //store the id and locations of the PowerUps, it is easier to find out which power up on the map is to be used or removed
                powerUp[i] = compassPower.coordinate
            }
        
        }
        
        
        //2nd power up
        //Get x and y coordinates of corners of the map
        let rx2 = self.map.bottomRightPoint.x
        let lx2 = self.map.topLeftPoint.x
        let ry2 = self.map.bottomRightPoint.y
        let ly2 = self.map.topLeftPoint.y
        
        //Generate random coordinate for the powerup
        let r2  = self.randomIn(lx2,rx2)
        let l2  = self.randomIn(ly2,ry2)
        self.tempLocation  = CLLocationCoordinate2D(latitude: r2, longitude: l2)
        
        
        
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
                self.MapView.removeAnnotation(self.temppin)
                
                // SETTING UP ARRAY OF VALUES TO BE POSTED TO DB
//                let mdata : [String: Double] = [
//                    "lat": self.lat, "long": self.long
//                ]
                
                // POSTING TO DB
                //self.db.child("locations").child(self.deviceId).setValue(mdata)
                
                // POSTING LAT LONG TO MAP
                self.tempLocation  = CLLocationCoordinate2D(latitude: self.lat, longitude: self.long)
                
                // DEBUG
                print(self.lat.description + " " + self.long.description)
                // END OF DEBUG
                
                self.temppin = CustomPointAnnotation()
                self.temppin.coordinate = self.tempLocation!
                
            
//               self.map = Map(topCorner: MKMapPoint(x: self.lat - self.mapRadius, y: self.long - self.mapRadius), botCorner: MKMapPoint(x: self.lat + self.mapRadius, y: self.long + self.mapRadius), tileSize: 1)
//                
//               self.MapView.setRegion(self.convertRectToRegion(rect: (self.map.mapActual)!), animated: true)
              
                self.temppin.playerRole = "hunter"
                
                // POSTING TO DB
                self.db.child("locations").child(self.deviceId).setValue(
                    ["lat": self.lat, "long": self.long ,"role": self.temppin.playerRole]
                )

                self.MapView.addAnnotation(self.temppin)
                
                /*
                // ANOTHER PIN
                if(self.lat2 == 0.0){
                    // set second pin somewhere above and to left of center pin
                    self.lat2 = location.coordinate.latitude + 0.003
                    self.long2 = location.coordinate.longitude - 0.003
                }
                
                // move the pin slowly to the right
                self.long2 = self.long2 + 0.0001
                
                // display second pin
                self.MapView.removeAnnotation(self.temppin2)
                self.tempLocation  = CLLocationCoordinate2D(latitude: self.lat2, longitude: self.long2)
                self.temppin2.coordinate = self.tempLocation!
                
                self.temppin2.playerRole = "playerTwo"
                self.MapView.addAnnotation(self.temppin2)
                
                // add the "arrow" on the second pin
                self.UnoDirections(pointA: self.temppin, pointB: self.temppin2);
                */
               
            }
        }
        
        
         //this sends the request to start fetching the location
        Notifications.postGpsToggled(self, toggle: true)
        

    }
    
    // remove the pin(power up), when it is used or collected by a player, from the map
    func activePowerUp(id: Int) {
        let thePowerUp = try! HiderInvisibility(id: id, duration: 30, isActive: false)
        thePowerUp.coordinate = powerUp[id]!
        self.MapView.removeAnnotation(thePowerUp)
    }

    
    func configureDatabase() {
        //init db
        db = FIRDatabase.database().reference()

        // read locations from db
        _refHandle = self.db.child("locations").observe(.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
//            strongSelf.locationsSnapshot = snapshot
            strongSelf.parseLocationsSnapshot(locations: snapshot)
            })
    }
    
    // parse locations from db, store in array of tuples
    func parseLocationsSnapshot(locations: FIRDataSnapshot) {
        // empty the array
        self.locations.removeAll()
        
        // REMOVING ALL THE PINS FROM THE DATABASE FIRST SO WE CAN UPDATE IT
        for index in pins {
            self.MapView.removeAnnotation(index!)
        }
        
        pins.removeAll()
        // loop through each device and retrieve device id, lat and long, store in locations array
        for child in locations.children.allObjects as? [FIRDataSnapshot] ?? [] {
            guard child.key != "(null" else { return }
            let childId = child.key
            let childLat = child.childSnapshot(forPath: "lat").value as! Double
            let childLong = child.childSnapshot(forPath: "long").value as! Double
            var playerRole = " "
            
            if(child.childSnapshot(forPath: "role").value as? String != nil){
                playerRole = child.childSnapshot(forPath: "role").value as! String
            } else {
                playerRole = "hinder"
            }
            
            self.locations += [(id: childId, lat: childLat, long: childLong )]
            
            // ADDING OTHER DEVICES FROM DB TO THE MAP AND SAVING THAT LOCATION INTO GLOBAL VAR PINS
            if childId != deviceId {
                
                var tempLocation : CLLocationCoordinate2D
                let temppin2  = CustomPointAnnotation()
                tempLocation  = CLLocationCoordinate2D(latitude: childLat, longitude: childLong)
                
                temppin2.coordinate = tempLocation
                temppin2.playerRole = playerRole
                pins.append(temppin2)
                // add arrows pointing to all devices
                
                self.MapView.addAnnotation(temppin2)
                
            }
        }
        pointToNearestPin()
        
        print("***** updated locations array ****** \(self.locations)")
        
        // call functions once array of locations is updated
        
    }
    
    //checks if a given power up id is within 5 meters of the user
    func powerUpDistanceTrigger(powerUpId : Int){
        
        
        
        // CLLocation of user pin
        let userLoc = CLLocation(latitude: temppin.coordinate.latitude, longitude: temppin.coordinate.longitude)

        let powerUpLocation = CLLocation(latitude: (powerUp[powerUpId]?.latitude)!, longitude: (powerUp[powerUpId]?.longitude)!)
                
        // get the distance between the user and the power up
        let distance = userLoc.distance(from: powerUpLocation)
        
        
        print("DISTANCE:" + String(distance) )
        
        print("USERLOCATION:" + String(userLoc.coordinate.latitude) + ":" + String(userLoc.coordinate.longitude) )
        print("POWERUPLOCATION:" + String(powerUpLocation.coordinate.latitude) + ":" + String(powerUpLocation.coordinate.longitude) )
        
        //prints message if user is within 5 meters of power up
        if(distance<=5){
            print("TRIGGER:USER WITHIN 5 METERS OF POWER UP")
        }

        
    }
    
    
    func pointToNearestPin(){
        
        
        if(pins.count > 0){
            // CLLocation of user pin
            let userLoc = CLLocation(latitude: temppin.coordinate.latitude, longitude: temppin.coordinate.longitude)
            
            // pin of current smallest distance
            let smallestDistancePin = CustomPointAnnotation()
            var smallestDistance = 10000000.0
            for pin in pins{
            
                // create a CLLocation for each pin
                let loc = CLLocation(latitude: (pin?.coordinate.latitude)!, longitude: (pin?.coordinate.longitude)!)
                
                // get the distance between pins
                let distance = userLoc.distance(from: loc)
                
                if(smallestDistance > distance){
                    smallestDistance = distance
                    
                    // assign pin to smallest distance pin
                    let tempLocation  = loc.coordinate
                    smallestDistancePin.coordinate = tempLocation
                }
            }
            
            // point arrow to smallest distance pin
            self.UnoDirections(pointA: self.temppin, pointB: smallestDistancePin);
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
            
            if customAnnotation.playerRole == "hunter" {
                annotationView!.image = self.resizeImage(image: UIImage(named: "team_red")!, targetSize: CGSize(30, 30))
            } else if customAnnotation.playerRole == "hider" {
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
