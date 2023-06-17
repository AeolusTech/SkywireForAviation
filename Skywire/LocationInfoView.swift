//
//  LocationInfoView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 17/06/2023.
//

import SwiftUI
import WeatherKit
import CoreLocation


struct LocationInfoView: View {
    let location: CLLocation =
    CLLocation(
        latitude: .init(floatLiteral: 30),
        longitude: .init(floatLiteral: 39)
    )
    
    @State var weather: Weather?
    
    func getWeather() async {
        do {
            weather = try await Task.detached(priority: .userInitiated) {
                return try await WeatherService.shared
                    .weather(for: locationViewModel.locationManager.location ?? CLLocation())
            }.value
        } catch {
            fatalError("\(error)")
        }
    }
    
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
                Text("Barometric Altitude:")
                    .font(.headline)
                Spacer()
                Text("\((locationViewModel.barometricAltitude), specifier: "%.2f") ft")
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
            HStack {
                Text("Current Pressure:")
                    .font(.headline)
                Spacer()
                Group {
                    if let weather = weather {
                        Text("\(weather.currentWeather.pressure.value) hPa")
                    } else {
                        ProgressView()
                            .task {
                                await getWeather()
                            }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
