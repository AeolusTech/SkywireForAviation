//
//  ContentView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct LocationData {
    var timestamp: TimeInterval
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var altitude: CLLocationDistance
    var heading: CLLocationDirection
}

protocol NetworkSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}
extension URLSession: NetworkSession { }

class LocationDataRecorder {
    private var csvHeader: String = "Timestamp,Latitude,Longitude,Altitude,Heading\n"
    private var csvData: String
    private var networkSession: NetworkSession

    init(networkSession: NetworkSession = URLSession.shared) {
        self.networkSession = networkSession
        self.csvData = self.csvHeader
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
                csvData = csvHeader
                uploadCSVDataToS3(fileURL: fileURL)
            } catch {
                print("Failed to save CSV file: (error)")
            }
        }
    }
    
    func uploadCSVDataToS3(fileURL: URL) {
        let endpoint = "https://5ktfkrdjuk.execute-api.eu-central-1.amazonaws.com/default/upload-flight-to-storage-v2"
        guard let url = URL(string: endpoint) else { return }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = fileData
            request.setValue("text/csv", forHTTPHeaderField: "Content-Type")
            request.setValue("lot-from-mobile.csv", forHTTPHeaderField: "Content-Disposition")
            
            let task = networkSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error uploading file: \(error)")
                } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    print("File uploaded successfully \(response)")
                    DispatchQueue.main.async {
                        self.showSuccessAlert()
                    }
                } else {
                    print("Unexpected response: \(String(describing: response))")
                }
            }
            task.resume()
        } catch {
            print("Error reading file data: \(error)")
        }
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Success", message: "File saved and uploaded successfully", preferredStyle: .alert)

        if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = firstScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        alert.dismiss(animated: true, completion: nil)
                    }
                })
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
    var authorizationStatusProvider: (() -> CLAuthorizationStatus)?

    var authorizationStatus: CLAuthorizationStatus {
        return authorizationStatusProvider?() ?? locationManager.authorizationStatus
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func startTimer(pollingRate: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollingRate, repeats: true) { _ in
            self.saveLocationData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManagerDidChangeAuthorization(manager)
        if let location = locations.last {
            currentLocation = location
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
        mapView.accessibilityIdentifier = "mapView"
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
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var shouldShowLocationWarning: Bool {
        return locationViewModel.locationManager.authorizationStatus != .authorizedAlways
    }
    
    var body: some View {
        VStack {
            if shouldShowLocationWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Location access is required to record data.")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.top)
                .onTapGesture {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }
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
                Text("\(max((locationViewModel.locationManager.location?.speed ?? 0) * 1.94384, 0), specifier: "%.2f") knots")
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
    
    var canStartRecording: Bool {
        return locationViewModel.locationManager.authorizationStatus == .authorizedAlways
    }
    
    func showLocationAccessMessage() {
        let message = "To record your location data, you need to allow Always location access in the Settings app."
        let alert = UIAlertController(title: "Location Access", message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = firstScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    var body: some View {
        if !locationViewModel.recording {
            if canStartRecording {
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
                    showLocationAccessMessage()
                }) {
                    Text("Location access not allowed")
                        .font(.title)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
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
            .environmentObject(LocationViewModel())
    }
}


