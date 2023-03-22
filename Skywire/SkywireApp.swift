//
//  SkywireApp.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import SwiftUI

@main
struct SkywireApp: App {
    @StateObject private var locationViewModel = LocationViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(locationViewModel)
        }
    }
}
