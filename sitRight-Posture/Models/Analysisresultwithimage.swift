//
//  AnalysisResultWithImage.swift
//  sitRight-Posture
//
//  Model to store analysis result with captured image
//

import SwiftUI
import Vision

/// A struct that combines the analysis result with the captured image and pose overlay
struct AnalysisResultWithImage: Identifiable, Equatable {
    let id = UUID()
    
    // Equatable conformance
    static func == (lhs: AnalysisResultWithImage, rhs: AnalysisResultWithImage) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// The captured image
    let capturedImage: UIImage
    
    /// The analyzed posture type
    let postureType: PostureType
    
    /// The angle measured for the posture
    let angle: Double
    
    /// A boolean indicating if the posture is within normal range
    let isNormal: Bool
    
    /// The confidence score of the analysis
    let confidence: Double
    
    /// The pose observation for drawing overlay
    let poseObservation: VNHumanBodyPoseObservation?
    
    /// Timestamp of when the analysis was performed
    let timestamp: Date
    
    /// Detailed recommendation based on the analysis
    let recommendation: String
    
    init(
        capturedImage: UIImage,
        postureType: PostureType,
        angle: Double,
        isNormal: Bool,
        confidence: Double,
        poseObservation: VNHumanBodyPoseObservation? = nil,
        recommendation: String
    ) {
        self.capturedImage = capturedImage
        self.postureType = postureType
        self.angle = angle
        self.isNormal = isNormal
        self.confidence = confidence
        self.poseObservation = poseObservation
        self.timestamp = Date()
        self.recommendation = recommendation
    }
    
    /// A string describing the status of the posture
    var status: String {
        isNormal ? "Good Posture" : "Needs Improvement"
    }
    
    /// The color representing the status of the posture
    var statusColor: Color {
        isNormal ? .green : .orange
    }
    
    /// A string describing the severity of the posture issue
    var severity: String {
        switch postureType {
        case .forwardHead:
            if angle >= 50 { return "Normal" }
            else if angle >= 45 { return "Mild" }
            else { return "Moderate to Severe" }
        case .roundedShoulder:
            if angle < 30 { return "Normal" }
            else if angle < 40 { return "Mild" }
            else { return "Moderate to Severe" }
        case .backSlouch:
            if angle <= 50 { return "Normal" }
            else if angle <= 60 { return "Mild" }
            else { return "Moderate to Severe" }
        }
    }
}
