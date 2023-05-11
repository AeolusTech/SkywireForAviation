//
//  RecordButtonUITest.swift
//  SkywireUITests
//
//  Created by Kamil Kuczaj on 08/04/2023.
//

import XCTest
import SwiftUI
@testable import Skywire

final class RecordButtonUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testRecordPositionButton() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("No window scene found")
        }
        
        let locationViewModel = LocationViewModel()
        locationViewModel.locationManager.allowsBackgroundLocationUpdates = true
        locationViewModel.authorizationStatusProvider = { return .authorizedAlways }
        let recordButton = RecordButton(locationViewModel: locationViewModel)
        let hostingController = UIHostingController(rootView: recordButton)
        if let window = windowScene.windows.first {
            window.rootViewController = hostingController
        }

        let recordPositionButton = app.buttons["Record position"]
        
        XCTAssertTrue(recordPositionButton.waitForExistence(timeout: 5))
        recordPositionButton.tap()

//        XCTAssertTrue(locationViewModel.recording)
    }

    func testStopRecordingButton() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("No window scene found")
        }
        
        let locationViewModel = LocationViewModel()
        locationViewModel.authorizationStatusProvider = { return .authorizedAlways }
        locationViewModel.recording = true
        let recordButton = RecordButton(locationViewModel: locationViewModel)
        let hostingController = UIHostingController(rootView: recordButton)
        if let window = windowScene.windows.first {
            window.rootViewController = hostingController
        }


        let stopRecordingButton = app.buttons["Stop recording"]
        
        XCTAssertTrue(stopRecordingButton.waitForExistence(timeout: 5))
        stopRecordingButton.tap()

//        XCTAssertFalse(locationViewModel.recording)
    }

    func testRecordPositionBlockedButton() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("No window scene found")
        }
        
        let locationViewModel = LocationViewModel()
        locationViewModel.authorizationStatusProvider = { return .denied }
        let recordButton = RecordButton(locationViewModel: locationViewModel)
        let hostingController = UIHostingController(rootView: recordButton)
        if let window = windowScene.windows.first {
            window.rootViewController = hostingController
        }


        let recordPositionBlockedButton = app.buttons["Location access not allowed"]
        
        XCTAssertTrue(recordPositionBlockedButton.waitForExistence(timeout: 5))
        recordPositionBlockedButton.tap()

        XCTAssertTrue(app.alerts["Location Access"].exists)
        app.alerts["Location Access"].buttons["Cancel"].tap()

//        XCTAssertFalse(locationViewModel.recording)
    }
}
