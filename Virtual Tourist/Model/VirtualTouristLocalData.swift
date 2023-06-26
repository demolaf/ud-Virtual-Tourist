//
//  VirtualTouristLocalData.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 24/06/2023.
//

import Foundation
import MapKit

struct VirtualTouristLocalData: Codable {
    let lastOpenedLocation: LastOpenedLocation
}

struct LastOpenedLocation: Codable {
    let latitude: Double
    let longitude: Double
}
