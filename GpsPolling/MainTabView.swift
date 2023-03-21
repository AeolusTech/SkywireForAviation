//
//  MainTabView.swift
//  GpsPolling
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Location Tracker")
                }
            
            RecordedFilesView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Recorded Files")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

