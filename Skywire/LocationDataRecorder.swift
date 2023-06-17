//
//  LocationDataRecorder.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 17/06/2023.
//

import SwiftUI
import MapKit
import Combine
import WeatherKit


struct LocationData {
    var timestamp: TimeInterval
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var altitude: CLLocationDistance
    var baroAltitude: CLLocationDistance
    var heading: CLLocationDirection
}

protocol NetworkSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}
extension URLSession: NetworkSession { }

class LocationDataRecorder {
    private var csvHeader: String = "Timestamp,Latitude,Longitude,Altitude,Barometric Altitude,Heading\n"
    private var csvData: String
    private var networkSession: NetworkSession

    init(networkSession: NetworkSession = URLSession.shared) {
        self.networkSession = networkSession
        self.csvData = self.csvHeader
    }

    func saveLocationData(_ locationData: LocationData) {
        let row = "\(locationData.timestamp),\(locationData.latitude),\(locationData.longitude),\(locationData.altitude),\(locationData.baroAltitude),\(locationData.heading)\n"
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
                    let msg = "File saved and uploaded successfully"
                    print("\(msg) \(response)")
                    DispatchQueue.main.async {
                        AlertUtility.showDisappearingAlert(title: "Success", message: msg)
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
}
