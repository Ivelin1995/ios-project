//
//  PowerUp.swift
//  ios-project
//
//  Created by Kevin Le on 2016-10-19.
//  Copyright © 2016 Manjot. All rights reserved.
//

import Foundation
import UIKit
import MapKit

protocol PowerUp{
    
    // name of the powerup
    var name : String { get set }
    
    // the role the powerup belongs to
    var role : String { get set }
    
    // how long the power up lasts when being used
    var duration : Int { get set }
    
    // true if the no player uses it
    var isActive : Bool { get set }
    
    // brief description of the powerup
    var powerDescription : String { get set }
    
    //icon
    var icon : UIImage {get set}
    
    init()
    
    init(id: Int, duration: Int,  isActive: Bool) throws
    
}
