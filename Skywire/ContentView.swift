//
//  ContentView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import SwiftUI
import CoreLocation

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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationViewModel())
    }
}


