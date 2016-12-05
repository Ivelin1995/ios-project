//
//  LobbyMapSelectView.swift
//  ios-project
//
//  Created by Jordan Hamade on 2016-12-01.
//  Copyright © 2016 Manjot. All rights reserved.
//

import UIKit
import MapKit

class LobbyMapSelectView: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate{
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var DoneButton: UIButton!
    
    @IBOutlet weak var ResetButton: UIButton!
    
    
    var annotationA = MKPointAnnotation()
    var annotationB = MKPointAnnotation()
    var polygon = MKPolygon()
    var lobby = LobbyViewController()
    
    var count = 0
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        let gestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(handleTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        ResetButton.addTarget(self, action: #selector(resetPins), for: .touchUpInside)
        ResetButton.backgroundColor = UIColor.clear
        
        
        //centering current location?
        let locationManager = CLLocationManager()
        let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: locValue.latitude, longitude: locValue.longitude), span: span)
        mapView.setRegion(region, animated: true)
        
        DoneButton.addTarget(self, action: #selector(finishView), for: .touchUpInside)
        DoneButton.backgroundColor = UIColor.clear
    }
    
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer){
        let location = gestureRecognizer.location(in: mapView)
        let x = mapView.convert(location, toCoordinateFrom: mapView)

        if(count == 0){
            annotationA.coordinate = x
            mapView.addAnnotation(annotationA)
            count += 1
        }else if(count == 1){
            annotationB.coordinate = x
            mapView.addAnnotation(annotationB)
            count += 1
            displayArea()
        }
    }
    
    func displayArea(){
        let p1 = MKMapPointForCoordinate(annotationA.coordinate)
        let p2 = MKMapPointForCoordinate(annotationB.coordinate)
        let p3 = MKMapPoint(x: p1.x, y: p2.y)
        let p4 = MKMapPoint(x: p2.x, y: p1.y)
        var points = [MKMapPoint]()
        points.append(p1)
        points.append(p3)
        points.append(p2)
        points.append(p4)
        
        polygon = MKPolygon(points: points, count: points.count)
        self.mapView.add(polygon)

    }
    
    func mapView(_ mapView:MKMapView, rendererFor overlay: MKOverlay)-> MKOverlayRenderer{
        let polygonView = MKPolygonRenderer(overlay:overlay)
        polygonView.strokeColor = UIColor.red
        polygonView.lineWidth = 1
        
        return polygonView
    }
    
    func resetPins(){
        count = 0
        mapView.removeAnnotation(annotationA)
        mapView.removeAnnotation(annotationB)
        self.mapView.remove(polygon)
    }
    
    func finishView(){
        self.lobby.mapCoordinate1 = annotationA.coordinate
        self.lobby.mapCoordinate2 = annotationB.coordinate
        self.dismiss(animated: true, completion: nil)
    }
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "doneSegue") {
            let guest = segue.destination as! LobbyViewController
            guest.mapCoordinate1 = annotationA.coordinate
            guest.mapCoordinate2 = annotationB.coordinate
        }
    }*/

}

