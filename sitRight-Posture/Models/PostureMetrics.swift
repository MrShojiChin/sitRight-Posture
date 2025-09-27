//
//  PostureMetrics.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


import Foundation

/// A struct that represents various metrics related to a person's posture at a specific time.
struct PostureMetrics {
    /// The angle between the neck and the head, used to detect forward head posture.
    var craniovertebralAngle: Double
    /// The angle of the shoulders, used to detect rounded shoulders.
    var shoulderFlexionAngle: Double
    /// The curvature of the upper back, used to detect slouching.
    var thoracicKyphosisAngle: Double
    /// The timestamp of when the metrics were recorded.
    var timestamp: Date = Date()
    
    /// A boolean value that indicates whether the person has forward head posture.
    var hasFHP: Bool {
        return craniovertebralAngle < 50.0
    }
    
    /// A boolean value that indicates whether the person has rounded shoulders.
    var hasRoundedShoulders: Bool {
        return shoulderFlexionAngle > 30.0
    }
    
    /// A boolean value that indicates whether the person is slouching.
    var hasBackSlouch: Bool {
        return thoracicKyphosisAngle > 50.0
    }
}