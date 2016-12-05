//
//  Notification.swift
//  test
//
//  Created by Dennis Chau on 2016-11-04.
//  Copyright © 2016 Dennis Chau. All rights reserved.
//

import Foundation
import CoreLocation


class Notifications
{
    fileprivate static let notificationCentre = NotificationCenter.default
    static let LocationUpdated = "LocationUpdated"
    static let Message = "Message"
    static let gpsToggled = "gpsToggled"
    
    fileprivate static func post(_ messageName: String!, object: AnyObject?, userInfo: [AnyHashable: Any]? = nil)
    {
        notificationCentre.post(name: Notification.Name(rawValue: messageName), object: object, userInfo: userInfo)
    }
    
    static func postLocationUpdated(_ object: AnyObject?, location: CLLocation!)
    {
        let userInfo =
            [
                "location" : location
        ]
        
        post(LocationUpdated, object: object, userInfo: userInfo)
    }

    static func postMessage(_ object: AnyObject?, message: String!)
    {
        let userInfo =
            [
                "message" : message
        ]
        
        post(Message, object: object, userInfo: userInfo)
    }

    static func getLocation(_ notification: Notification!) -> CLLocation?
    {
        let location = notification.userInfo?["location"] as? CLLocation
        
        return location
    }
    
    static func postGpsToggled(_ object: AnyObject?, toggle: Bool!)
    {
        let userInfo =
            [
                "gpsToggled" : toggle
        ]
        
        post(gpsToggled, object: object, userInfo: userInfo)
    }
    
    static func getGpsToggled(_ notification: Notification!) -> Bool?
    {
        let toggle = notification.userInfo?["gpsToggled"] as? Bool
        
        return toggle
    }
    
}
