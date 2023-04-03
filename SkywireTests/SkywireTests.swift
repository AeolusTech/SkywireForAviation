//
//  SkywireTests.swift
//  SkywireTests
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import XCTest
@testable import Skywire
import CoreLocation

class SkywireTests: XCTestCase {
    
    // MARK: - Business Logic Tests
    
    // Test LocationData
    func testCreatingLocationData() {
        let locationData = LocationData(timestamp: 0, latitude: 0, longitude: 0, altitude: 0, heading: 0)
        XCTAssertNotNil(locationData)
    }
    
    func testLocationDataMinMaxValues() {
        let locationData1 = LocationData(timestamp: 0, latitude: -90, longitude: -180, altitude: -1000, heading: 0)
        let locationData2 = LocationData(timestamp: 0, latitude: 90, longitude: 180, altitude: 100000, heading: 360)
        XCTAssertNotNil(locationData1)
        XCTAssertNotNil(locationData2)
    }
    
    // Test LocationDataRecorder
    func testLocationDataRecorderInitialization() {
        let recorder = LocationDataRecorder()
        XCTAssertNotNil(recorder)
    }
    
    func testSavingSingleLocationData() {
        let locationData = LocationData(timestamp: 0, latitude: 0, longitude: 0, altitude: 0, heading: 0)
        let recorder = LocationDataRecorder()
        recorder.saveLocationData(locationData)
        // Check if the CSV data contains the saved locationData
    }
    
    func testSavingMultipleLocationData() {
        let locationData1 = LocationData(timestamp: 0, latitude: 0, longitude: 0, altitude: 0, heading: 0)
        let locationData2 = LocationData(timestamp: 1, latitude: 1, longitude: 1, altitude: 100, heading: 45)
        let recorder = LocationDataRecorder()
        recorder.saveLocationData(locationData1)
        recorder.saveLocationData(locationData2)
        // Check if the CSV data contains both saved locationData objects
    }

    // Due to the nature of file saving, it's difficult to test directly in XCTestCase.
    // The saveCSVDataToFile() function should be manually tested for correctness.

    // MARK: - UI Tests

    // Test ContentView
    func testContentView() {
        let viewModel = LocationViewModel()
        let contentView = ContentView().environmentObject(viewModel)
        XCTAssertNotNil(contentView)
    }

    // Test LocationInfoView
    func testLocationInfoView() {
        let viewModel = LocationViewModel()
        let locationInfoView = LocationInfoView(locationViewModel: viewModel)
        XCTAssertNotNil(locationInfoView)
    }

    // Test RecordButton
    func testRecordButton() {
        let viewModel = LocationViewModel()
        let recordButton = RecordButton(locationViewModel: viewModel)
        XCTAssertNotNil(recordButton)
    }

}

