//
//  KalmanFilter.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 08/08/2023.
//

import Foundation
import CoreLocation

class KalmanFilter {
    var estimate: CLLocation
    var estimateErrorCovariance: Double
    let measurementErrorCovariance: Double
    let processErrorCovariance: Double

    init(initialEstimate: CLLocation, initialEstimateErrorCovariance: Double, measurementErrorCovariance: Double, processErrorCovariance: Double) {
        self.estimate = initialEstimate
        self.estimateErrorCovariance = initialEstimateErrorCovariance
        self.measurementErrorCovariance = measurementErrorCovariance
        self.processErrorCovariance = processErrorCovariance
    }

    func update(measurement: CLLocation) {
        let kalmanGain = estimateErrorCovariance / (estimateErrorCovariance + measurementErrorCovariance)
        estimate = CLLocation(latitude: estimate.coordinate.latitude + kalmanGain * (measurement.coordinate.latitude - estimate.coordinate.latitude),
                              longitude: estimate.coordinate.longitude + kalmanGain * (measurement.coordinate.longitude - estimate.coordinate.longitude))
        estimateErrorCovariance = (1 - kalmanGain) * (estimateErrorCovariance + processErrorCovariance)
    }
}
