//
//  SkywireUITests.swift
//  SkywireUITests
//
//  Created by Kamil Kuczaj on 20/03/2023.
//

import XCTest

class SkywireUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testContent() {
        let mapView = app.otherElements["mapView"]
        XCTAssert(mapView.exists)

        let locationTrackerLabel = app.staticTexts["Location Tracker"]
        XCTAssert(locationTrackerLabel.exists)

        let recordButton = app.buttons["Record position"]
        XCTAssert(recordButton.exists)
        recordButton.tap()

        let stopButton = app.buttons["Stop recording"]
        XCTAssert(stopButton.exists)
        stopButton.tap()

        let latitudeLabel = app.staticTexts["Latitude:"]
        XCTAssert(latitudeLabel.exists)

        let longitudeLabel = app.staticTexts["Longitude:"]
        XCTAssert(longitudeLabel.exists)

        let altitudeLabel = app.staticTexts["Altitude:"]
        XCTAssert(altitudeLabel.exists)

        let baroAltitudeLabel = app.staticTexts["Barometric Altitude:"]
        XCTAssert(baroAltitudeLabel.exists)
        
        let speedLabel = app.staticTexts["Speed:"]
        XCTAssert(speedLabel.exists)

        let magneticHeadingLabel = app.staticTexts["Magnetic Heading:"]
        XCTAssert(magneticHeadingLabel.exists)
        
        let currentPressureLabel = app.staticTexts["Current Pressure:"]
        XCTAssert(currentPressureLabel.exists)
    }
}
