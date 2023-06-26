//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 24/06/2023.
//

import Foundation
import CoreData
import MapKit

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}

class PinAnnotation: MKPointAnnotation {
    var pin: Pin
    
    init(pin: Pin) {
        self.pin = pin
        super.init()
        
        self.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
    }
}
