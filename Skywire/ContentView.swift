//
//  ContentView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationData {
    var timestamp: TimeInterval
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var altitude: CLLocationDistance
    var heading: CLLocationDirection
}

class LocationDataRecorder {
    private var csvHeader: String = "Timestamp,Latitude,Longitude,Altitude,Heading\n"
    private var csvData: String

    init() {
        csvData = csvHeader
    }

    func saveLocationData(_ locationData: LocationData) {
        let row = "\(locationData.timestamp),\(locationData.latitude),\(locationData.longitude),\(locationData.altitude),\(locationData.heading)\n"
        csvData.append(row)
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
            }
        }
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Success",
                                      message: "File saved successfully",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))

        if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = firstScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationManager = CLLocationManager()
    private var locationDataRecorder = LocationDataRecorder()
    @Published var currentHeading: CLLocationDirection = 0
    @Published var currentLocation: CLLocation?
    private var timer: Timer?
    
    var pollingRate: TimeInterval = 0.5 {
        didSet {
            startTimer()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollingRate, repeats: true) { _ in
            self.saveLocationData()
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        startTimer()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManagerDidChangeAuthorization(manager)
        if let location = locations.last {
            currentLocation = location
        }
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

struct ContentView: View {
@StateObject private var locationViewModel = LocationViewModel()
    var body: some View {
        VStack {
            MapView(coordinate: .constant(locationViewModel.currentLocation?.coordinate ?? CLLocationCoordinate2D()))
                .frame(height: 300)

            Text("Location Tracker")
                .font(.largeTitle)
                .padding()

            RecordButton(locationViewModel: locationViewModel)

            LocationInfoView(locationViewModel: locationViewModel)
        }
    }
}

struct LocationInfoView: View {
    @ObservedObject var locationViewModel: LocationViewModel
    var body: some View {
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
}

struct RecordButton: View {
    @ObservedObject var locationViewModel: LocationViewModel
    var body: some View {
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


