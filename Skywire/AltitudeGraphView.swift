//
//  AltitudeGraphView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 27/03/2023.
//

import Charts
import SwiftUI

struct AltitudeGraphView: View {
    @State private var selectedUnit = 0
    private let units = ["m/s", "ft/min", "%"]

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
        
            AltitudeChartView(recordedData: recordedData, selectedUnit: $selectedUnit)
                .frame(height: 300)

            Picker("Gradient Units:", selection: $selectedUnit) {
                ForEach(0 ..< units.count) {
                    Text(self.units[$0])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top)
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
        @Binding var selectedUnit: Int
        
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
            
            // Add gradient marker
            let gradientMarker = GradientMarkerView()
            gradientMarker.chartView = chartView
            gradientMarker.recordedData = recordedData
            gradientMarker.selectedUnit = selectedUnit
            chartView.marker = gradientMarker
            
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
            if let gradientMarker = uiView.marker as? GradientMarkerView {
                gradientMarker.selectedUnit = selectedUnit
            }
        }
    }
    
    class GradientMarkerView: MarkerView {
        var recordedData: [RecordedData] = []
        var selectedUnit: Int = 0
        private var labelText: String = ""

        override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
            super.refreshContent(entry: entry, highlight: highlight)

            if let index = recordedData.firstIndex(where: { $0.date.timeIntervalSince1970 == entry.x }) {
                if index > 0 {
                    let deltaTime = recordedData[index].date.timeIntervalSince(recordedData[index - 1].date)
                    let deltaAltitude = recordedData[index].altitude - recordedData[index - 1].altitude

                    if deltaTime != 0 {
                        let gradient = deltaAltitude / deltaTime

                        switch selectedUnit {
                        case 1: // ft/min
                            let gradientInFeetPerMinute = gradient * 196.8504
                            labelText = String(format: "Gradient: %.2f ft/min", gradientInFeetPerMinute)
                        case 2: // %
                            let gradientPercentage = (deltaAltitude / deltaTime) * 100
                            labelText = String(format: "Gradient: %.2f %%", gradientPercentage)
                        default: // m/s
                            labelText = String(format: "Gradient: %.2f m/s", gradient)
                        }
                    }
                }
            }
        }
        
        override func draw(context: CGContext, point: CGPoint) {
            let boxRect = CGRect(
                x: point.x - (labelText.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]).width / 2) - 8,
                y: point.y - 36,
                width: labelText.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]).width + 16,
                height: 24
            )

            context.setFillColor(UIColor.systemGray.cgColor)
            context.fill(CGRect(origin: boxRect.origin, size: boxRect.size))
            
            labelText.draw(
                with: CGRect(origin: CGPoint(x: boxRect.origin.x + 8, y: boxRect.origin.y + 4), size: boxRect.size),
                options: .usesLineFragmentOrigin,
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ],
                context: nil
            )
        }
    }
}


struct AltitudeGraphView_Previews: PreviewProvider {
    static var previews: some View {
        AltitudeGraphView(fileURL: URL(filePath: ""))
            .environmentObject(LocationViewModel())
    }
}
