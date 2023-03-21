//
//  SettingsView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @AppStorage("pollingRate") private var pollingRate: String = "1.0"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Polling Rate")) {
                    TextField("Polling rate", text: $pollingRate)
                        .keyboardType(.decimalPad)
                        .onReceive(Just(pollingRate)) { newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "," }
                            if filtered != newValue {
                                self.pollingRate = filtered
                            }
                        }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
