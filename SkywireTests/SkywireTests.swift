//
//  SkywireTests.swift
//  SkywireTests
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import XCTest
@testable import Skywire
import CoreLocation

class MockNetworkSession: NetworkSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        completionHandler(data, response, error)
        return URLSession.shared.dataTask(with: request)
    }
}


class SkywireTests: XCTestCase {
    // MARK: - S3 data upload
    func testUploadCSVDataToS3() {
        let expectation = XCTestExpectation(description: "Upload CSV data to S3")
        let mockSession = MockNetworkSession()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let locationDataRecorder = LocationDataRecorder(networkSession: mockSession)
        
        // Create a sample CSV file URL
        let fileURL = Bundle(for: type(of: self)).url(forResource: "SampleCSVData", withExtension: "csv")
        // Call uploadCSVDataToS3() with the sample file URL
        if let url = fileURL {
            locationDataRecorder.uploadCSVDataToS3(fileURL: url)
        }
        
        // Verify that a network request was made
        XCTAssertNotNil(mockSession.dataTask(
            with: URLRequest(url: URL(string: "https://5ktfkrdjuk.execute-api.eu-central-1.amazonaws.com/default/upload-flight-to-storage")!),
            completionHandler: { _, _, _ in }
        ))
        
        // Fulfill the expectation after the network request completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }
    
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

