//
//  AltitudeGraphView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 27/03/2023.
//

import Charts
import SwiftUI

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
        VStack(alignment: .leading) {
            Text(fileURL.lastPathComponent)
                .font(.title)
                .padding(.bottom)
            
            Text("Date created: " + fileCreationDateString())
                .font(.caption)
        
            AltitudeChartView(recordedData: recordedData)
                .frame(height: 300)
        }
    }
    
    private func fileCreationDateString() -> String {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                return formatter.string(from: creationDate)
            }
        } catch {
            print("Error getting file creation date: \(error)")
        }
        
        return "Unknown"
    }
    
    struct AltitudeChartView: UIViewRepresentable {
        var recordedData: [RecordedData]
        
        func makeUIView(context: Context) -> LineChartView {
            let chartView = LineChartView()
            
            // Enable zooming and navigation
            chartView.setScaleEnabled(true)
            chartView.dragEnabled = true
            chartView.pinchZoomEnabled = true
            chartView.doubleTapToZoomEnabled = true
            
            let dataEntries = recordedData.map { ChartDataEntry(x: $0.date.timeIntervalSince1970, y: $0.altitude) }
            
            let dataSet = LineChartDataSet(entries: dataEntries)
            dataSet.drawCirclesEnabled = false
            dataSet.mode = .cubicBezier
            dataSet.lineWidth = 2
            
            let chartData = LineChartData(dataSet: dataSet)
            chartView.data = chartData
            
            // Customize x-axis value formatter
            let xAxis = chartView.xAxis
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            xAxis.valueFormatter = DefaultAxisValueFormatter(block: { (value, _) -> String in
                let date = Date(timeIntervalSince1970: value)
                return dateFormatter.string(from: date)
            })
            
            // Configure other x-axis properties (optional)
            xAxis.labelPosition = .bottom
            xAxis.labelRotationAngle = -45
            xAxis.drawGridLinesEnabled = false
            xAxis.forceLabelsEnabled = true
            xAxis.granularity = 1
            
            return chartView
        }

        
        func updateUIView(_ uiView: LineChartView, context: Context) {
            let dataEntries = recordedData.map { ChartDataEntry(x: $0.date.timeIntervalSince1970, y: $0.altitude) }
            
            if let dataSet = uiView.data?.dataSets.first as? LineChartDataSet {
                dataSet.replaceEntries(dataEntries)
                uiView.data?.notifyDataChanged()
                uiView.notifyDataSetChanged()
            } else {
                let dataSet = LineChartDataSet(entries: dataEntries)
                dataSet.drawCirclesEnabled = false
                dataSet.mode = .cubicBezier
                dataSet.lineWidth = 2
                
                let chartData = LineChartData(dataSet: dataSet)
                uiView.data = chartData
            }
        }
    }
}
