//
//  LocationViewModel.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 17/06/2023.
//

import CoreLocation
import CoreMotion
import WeatherKit
import SwiftUI

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationManager = CLLocationManager()
    private var locationDataRecorder = LocationDataRecorder()
    @Published var currentHeading: CLLocationDirection = 0
    @Published var currentLocation: CLLocation?
    private var timer: Timer?
    var authorizationStatusProvider: (() -> CLAuthorizationStatus)?
    private let altimeter = CMAltimeter()
    @Published var barometricAltitude: Double = 0.0
    @State var weather: Weather?
    
    private var kalmanFilter: KalmanFilter?

    func getWeather() async {
        do {
            if let currentLocation = self.locationManager.location {
                weather = try await Task.detached(priority: .userInitiated) {
                    print("Got weather for current location)")
                    return try await WeatherService().weather(for: currentLocation    )
                }.value
                print("Localised but still waiting on weather...")
            }
            else {
                print("Cannot get weather because I don't have location")
            }
        } catch {
            AlertUtility.showDisappearingAlert(title: "Fatal error", message: error.localizedDescription)
            print("\(error)")
        }
    }

    var authorizationStatus: CLAuthorizationStatus {
        return authorizationStatusProvider?() ?? locationManager.authorizationStatus
    }
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers // for rough estimate
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { (altitudeData, error) in
                guard let altitudeData = altitudeData else { return }
                let altitudeInMeters = altitudeData.relativeAltitude.doubleValue
                let altitudeInFeet = altitudeInMeters * 3.28084
                DispatchQueue.main.async {
                    self.barometricAltitude = altitudeInFeet
                }
            }
        }
    }
    
    func startTimer(pollingRate: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollingRate, repeats: true) { _ in
            self.saveLocationData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManagerDidChangeAuthorization(manager)

        // Initialize Kalman filter with the rough estimate if it's the first time
        if kalmanFilter == nil, let initialLocation = locations.first {
            kalmanFilter = KalmanFilter(initialEstimate: initialLocation,
                                        initialEstimateErrorCovariance: 1,
                                        measurementErrorCovariance: 1,
                                        processErrorCovariance: 0.01)
            
            // After getting the initial location, set the location manager for higher accuracy
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        // Update the Kalman filter with new locations
        else if let newLocation = locations.last, let filter = kalmanFilter {
            filter.update(measurement: newLocation)
            currentLocation = filter.estimate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        locationManagerDidChangeAuthorization(manager)
        currentHeading = newHeading.magneticHeading
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus
        {
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func saveLocationData() {
        if recording, let location = locationManager.location {
            let locationData = LocationData(timestamp: Date().timeIntervalSince1970,
                                            latitude: location.coordinate.latitude,
                                            longitude: location.coordinate.longitude,
                                            altitude: location.altitude,
                                            baroAltitude: barometricAltitude,
                                            heading: currentHeading)
            locationDataRecorder.saveLocationData(locationData)
        }
    }
    
    func saveCSVDataToFile() {
        locationDataRecorder.saveCSVDataToFile()
    }
    
    @Published var recording = false
    
    func startRecording() {
        recording = true
    }
    
    func stopRecording() {
        recording = false
        saveCSVDataToFile()
    }
}
