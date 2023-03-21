//
//  ContentView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isUserInteractionEnabled = false
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setCenter(coordinate, animated: true)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)
        
        uiView.removeAnnotations(uiView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        uiView.addAnnotation(annotation)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
    }
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationManager = CLLocationManager()
    @Published var csvData: String = "Timestamp,Latitude,Longitude,Altitude\n"
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var currentHeading: CLLocationDirection = 0

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        locationManagerDidChangeAuthorization(manager)
        print("Heading updated: \(newHeading.magneticHeading)")
        currentHeading = newHeading.magneticHeading
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.saveLocationData()
        }
    }
    
    func showSuccessAlert() {
            alertMessage = "File saved successfully."
            showAlert = true
    }
//
//    func showFailAlert(error: Error) {
//            alertMessage = "Error saving file! Error: \(error)"
//            showAlert = true
//    }
    
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
                showSuccessAlert()
            } catch {
                print("Failed to save CSV file: \(error)")
//                showFailAlert(error: error)
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
            MapView(coordinate: .constant(locationViewModel.locationManager.location?.coordinate ?? CLLocationCoordinate2D()))
                .frame(height: 300)
            
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Latitude:")
                        .font(.headline)
                    Spacer()
                    Text("\(locationViewModel.locationManager.location?.coordinate.latitude ?? 0, specifier: "%.6f")")
                        .font(.body)
                }
                HStack {
                    Text("Longitude:")
                        .font(.headline)
                    Spacer()
                    Text("\(locationViewModel.locationManager.location?.coordinate.longitude ?? 0, specifier: "%.6f")")
                        .font(.body)
                }
                HStack {
                    Text("Altitude:")
                        .font(.headline)
                    Spacer()
                    Text("\((locationViewModel.locationManager.location?.altitude ?? 0) * 3.28084, specifier: "%.2f") ft")
                        .font(.body)
                }
                HStack {
                    Text("Speed:")
                        .font(.headline)
                    Spacer()
                    Text("\((locationViewModel.locationManager.location?.speed ?? 0) * 1.94384, specifier: "%.2f") knots")
                        .font(.body)
                }
                HStack {
                    Text("Magnetic Heading:")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(locationViewModel.currentHeading))°")
                        .font(.body)
                }
            }
            .padding(.horizontal)
        }
        .alert(isPresented: $locationViewModel.showAlert) {
            Alert(title: Text("Success"), message: Text(locationViewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
