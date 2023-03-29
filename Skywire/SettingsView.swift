//
//  SettingsView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()

                Button(action: {
                    locationViewModel.pollingRate = max(locationViewModel.pollingRate - 0.1, 0.1)
                }) {
                    Image(systemName: "minus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }

                Form {
                    Section(header: Text("Polling Rate")) {
                        Text("\(locationViewModel.pollingRate, specifier: "%.1f") s")
                            .font(.title)
                    }
                }

                Button(action: {
                    locationViewModel.pollingRate = min(locationViewModel.pollingRate + 0.1, 2.0)
                }) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

