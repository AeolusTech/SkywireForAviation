//
//  AltitudeGraphView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 27/03/2023.
//

import SwiftUI
import Charts


struct AltitudeGraphView: View {
    struct RecordedData: Identifiable {
        let id = UUID()
        let date: Date
        let altitude: Double
    }
    
    var fileURL: URL
    var recordedData: [RecordedData] {
        var data = [RecordedData]()
        if let contents = try? String(contentsOf: fileURL) {
            let rows = contents.components(separatedBy: .newlines)
            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count == 5, let timestamp = Double(columns[0]), let altitude = Double(columns[3]) {
                    let recordedData = RecordedData(date: Date(timeIntervalSince1970: timestamp), altitude: altitude)
                    data.append(recordedData)
                }
            }
        }
        return data
    }
    
    var body: some View {
        VStack {
            Chart {
                ForEach(recordedData) { data in
                    LineMark(
                        x: .value("Timestamp", data.date),
                        y: .value("Altitude", data.altitude)
                    )
                }
            }
            .frame(height: 300)
        }
    }
}

