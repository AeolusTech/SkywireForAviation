//
//  SettingsView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct SettingsView: View {
    @Binding var pollingRate: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()

                Button(action: {
                    pollingRate = max(pollingRate - 0.1, 0.1)
                }) {
                    Image(systemName: "minus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }

                Form {
                    Section(header: Text("Polling Rate")) {
                        Text("\(pollingRate, specifier: "%.1f") s")
                            .font(.title)
                    }
                }

                Button(action: {
                    pollingRate = min(pollingRate + 0.1, 2.0)
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
        let pollingRate = Binding.constant(0.5)
        return SettingsView(pollingRate: pollingRate)
    }
}

