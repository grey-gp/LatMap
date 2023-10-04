//
//  CityData.swift
//  LatitudeSimilarity
//
//  Created by Graham Pennington on 9/6/22.
//

import Foundation
import CoreLocation


struct CityData: Hashable, Decodable {
    let city: String
    let lat: Double
    let lng: Double
    let country: String
    let iso2: String
}

struct CoordinateData: Identifiable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let iso2: String
}
