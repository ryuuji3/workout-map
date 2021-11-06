//
//  LocationManager.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-24.
//

import Foundation
import CoreLocation
import Combine
import os

private let logger = Logger(
    subsystem: "ryuuji3.workout-map.LocationManager",
    category: "LocationManager"
)

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    @Published var isAuthorized = false
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Error from LocationManager: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logger.log("Authorization changed")
        
        switch(manager.authorizationStatus) {
            case .authorizedWhenInUse:
                logger.log("Authorized for in-use")
                self.isAuthorized = true
                break
            case .authorizedAlways:
                logger.log("Authorized always")
                self.isAuthorized = true
                break
            default:
                logger.warning("Not authorized.")
                break // nothing to do
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locationManager.location {
            self.currentLocation = lastLocation
            logger.log("Location received! Stopping location service.")
            
            locationManager.stopUpdatingLocation()
        }
    }
    
    func getLocation() {
        logger.log("Requesting authorization and location")
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}
