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
        if recording, let location = locationManager.location {
            let timestamp = Date().timeIntervalSince1970
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let altitude = location.altitude
            
            let row = "\(timestamp),\(latitude),\(longitude),\(altitude)\n"
            csvData.append(row)
        }
    }
    
    func saveCSVDataToFile() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "LocationData_\(dateString).csv"
        
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            do {
                try csvData.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
                print("CSV file saved: \(fileURL)")
            } catch {
                print("Failed to save CSV file: \(error)")
            }
        }
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

struct ContentView: View {
    @StateObject private var locationViewModel = LocationViewModel()
    
    var body: some View {
        VStack {
            Text("Location Tracker")
                .font(.largeTitle)
                .padding()
            
            if !locationViewModel.recording {
                Button(action: {
                    locationViewModel.startRecording()
                }) {
                    Text("Record position")
                        .font(.title)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            } else {
                Button(action: {
                    locationViewModel.stopRecording()
                }) {
                    Text("Stop recording")
                        .font(.title)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
