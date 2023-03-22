//
//  MainTabView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var body: some View {
        TabView {
            ContentView()
                .environmentObject(locationViewModel)
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Location Tracker")
                }
            
            RecordedFilesView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Recorded Files")
                }
            SettingsView(pollingRate: $locationViewModel.pollingRate)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(LocationViewModel())
    }
}

