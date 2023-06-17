//
//  RecordButton.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 17/06/2023.
//

import SwiftUI

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
