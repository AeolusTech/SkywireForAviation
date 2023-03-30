//
//  MainTabView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var locationViewModel = LocationViewModel()
    @State private var pollingRate: TimeInterval = 0.5

    var body: some View {
        TabView {
            ContentView()
                .environmentObject(locationViewModel)
                .tabItem {
                    Image(systemName: "location")
                    Text("Location")
                }
            
            RecordedFilesView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Recorded Files")
                }
            SettingsView(pollingRate: $pollingRate)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .onAppear {
            locationViewModel.startTimer(pollingRate: pollingRate)
        }
        .onChange(of: pollingRate) { newPollingRate in
            locationViewModel.startTimer(pollingRate: newPollingRate)
        }
    }
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(LocationViewModel())
    }
}
