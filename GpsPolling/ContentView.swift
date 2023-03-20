//
//  ContentView.swift
//  GpsPolling
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import SwiftUI
import CoreLocation

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationManager = CLLocationManager()
    @Published var csvData: String = "Timestamp,Latitude,Longitude,Altitude\n"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.saveLocationData()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func saveLocationData() {
        if let location = locationManager.location {
            let timestamp = Date().timeIntervalSince1970
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let altitude = location.altitude
            
            let row = "\(timestamp),\(latitude),\(longitude),\(altitude)\n"
            csvData.append(row)
        }
    }
    
    func saveCSVDataToFile() {
        let fileName = "LocationData.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try csvData.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            print("CSV file saved: \(String(describing: path))")
        } catch {
            print("Failed to save CSV file: \(error)")
        }
    }
}

struct ContentView: View {
    @StateObject private var locationViewModel = LocationViewModel()
    
    var body: some View {
        Text("Location Tracker")
            .padding()
            .onDisappear {
                locationViewModel.saveCSVDataToFile()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
