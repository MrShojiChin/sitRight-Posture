//
//  PostureMetrics.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


import Foundation

struct PostureMetrics {
    var craniovertebralAngle: Double
    var shoulderFlexionAngle: Double  
    var thoracicKyphosisAngle: Double
    var timestamp: Date = Date()
    
    var hasFHP: Bool {
        return craniovertebralAngle < 50.0
    }
    
    var hasRoundedShoulders: Bool {
        return shoulderFlexionAngle > 30.0
    }
    
    var hasBackSlouch: Bool {
        return thoracicKyphosisAngle > 50.0
    }
}