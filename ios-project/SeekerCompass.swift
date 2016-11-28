//
//  SeekerCompass.swift
//  ios-project
//
//  Created by Kevin Le on 2016-10-19.
//  Copyright © 2016 Manjot. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class SeekerCompass : MKPointAnnotation, PowerUp {
    
    static let DEFAULT_NAME  = "Compass"
    static let DEFAULT_ROLE  = "Seeker"
    static let DEFAULT_DESC  = "Shows the direction the hider is at for a period of time"
    
    var id : Int
    var name : String
    var role : String
    var duration : Int
    var isActive : Bool
    var powerDescription : String
    var icon : UIImage
    
    required override init(){
        self.name        = SeekerCompass.DEFAULT_NAME
        self.role        = SeekerCompass.DEFAULT_ROLE
        self.powerDescription = SeekerCompass.DEFAULT_DESC
        
        
        self.id = 0
        self.duration    = 60 * 3
        self.isActive    = false
        self.icon        = UIImage(named: "compass")!
        super.init()
        self.icon        = self.resizeImage(image: UIImage(named: "compass")!, targetSize: CGSize(30, 30))
        
    }
    
    required init(id: Int, duration: Int, isActive: Bool) throws{
        self.name        = SeekerCompass.DEFAULT_NAME
        self.role        = SeekerCompass.DEFAULT_ROLE
        self.powerDescription = SeekerCompass.DEFAULT_DESC
        self.icon        = UIImage(named: "compass")!
        
        self.id = id
        
        if(duration <= 0 ){
            throw PowerUpError.illegalArgument
        }else{
            self.duration    = duration
            self.isActive    = isActive
        }
        super.init()
        self.icon        = self.resizeImage(image: UIImage(named: "compass")!, targetSize: CGSize(30, 30))
    }
    
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
    
}
