//
//  OrientationDetector.swift
//  sitRight-Posture
//
//  Created by Ryu on 26/9/2568 BE.
//


// OrientationDetector.swift - Put in Services folder
import Vision
import CoreGraphics

class OrientationDetector {
    // Confidence thresholds
    private let VISIBILITY_THRESHOLD: Float = 0.5
    private let OCCLUSION_THRESHOLD: Float = 0.1
    
    enum Orientation {
        case sidewaysLeft
        case sidewaysRight
        case front
        case back
        case unknown
        
        var isSideways: Bool {
            return self == .sidewaysLeft || self == .sidewaysRight
        }
        
        var description: String {
            switch self {
            case .sidewaysLeft: return "Left Profile"
            case .sidewaysRight: return "Right Profile"
            case .front: return "Facing Front"
            case .back: return "Facing Back"
            case .unknown: return "Unknown"
            }
        }
    }
    
    // Main detection function
    func detectOrientation(from pose: VNHumanBodyPoseObservation) -> Orientation {
        // Get shoulder points
        guard let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
              let rightShoulder = try? pose.recognizedPoint(.rightShoulder) else {
            return .unknown
        }
        
        // Get ear points for additional validation
        let leftEar = try? pose.recognizedPoint(.leftEar)
        let rightEar = try? pose.recognizedPoint(.rightEar)
        
        // Check shoulder visibility
        let leftShoulderVisible = leftShoulder.confidence > VISIBILITY_THRESHOLD
        let rightShoulderVisible = rightShoulder.confidence > VISIBILITY_THRESHOLD
        let leftShoulderOccluded = leftShoulder.confidence < OCCLUSION_THRESHOLD
        let rightShoulderOccluded = rightShoulder.confidence < OCCLUSION_THRESHOLD
        
        // Check for sideways orientation
        if leftShoulderVisible && rightShoulderOccluded {
            // Person is turned to their right (showing left side to camera)
            return .sidewaysLeft
        } else if rightShoulderVisible && leftShoulderOccluded {
            // Person is turned to their left (showing right side to camera)
            return .sidewaysRight
        } else if leftShoulderVisible && rightShoulderVisible {
            // Both shoulders visible - likely front or back view
            // Use ears to distinguish
            if let leftEar = leftEar, let rightEar = rightEar,
               leftEar.confidence > VISIBILITY_THRESHOLD && rightEar.confidence > VISIBILITY_THRESHOLD {
                return .front
            } else {
                return .back
            }
        } else {
            return .unknown
        }
    }
    
    // Simplified version matching your example
    func isPersonSideways(pose: VNHumanBodyPoseObservation) -> Bool {
        guard let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
              let rightShoulder = try? pose.recognizedPoint(.rightShoulder) else {
            return false
        }
        
        // Logic to detect if a person is turned sideways
        let isTurnedRight = leftShoulder.confidence > VISIBILITY_THRESHOLD &&
                           rightShoulder.confidence < OCCLUSION_THRESHOLD
        let isTurnedLeft = rightShoulder.confidence > VISIBILITY_THRESHOLD &&
                          leftShoulder.confidence < OCCLUSION_THRESHOLD
        
        return isTurnedLeft || isTurnedRight
    }
    
    // Get confidence score for side view
    func getSideViewConfidence(pose: VNHumanBodyPoseObservation) -> Float {
        guard let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
              let rightShoulder = try? pose.recognizedPoint(.rightShoulder) else {
            return 0
        }
        
        // Calculate confidence based on how clearly one shoulder is visible and other is hidden
        let leftVisibility = leftShoulder.confidence
        let rightVisibility = rightShoulder.confidence
        
        // For side view, we want high difference between shoulders
        let visibilityDifference = abs(leftVisibility - rightVisibility)
        
        // Also check that one is clearly visible and the other is clearly hidden
        let hasVisibleShoulder = max(leftVisibility, rightVisibility) > VISIBILITY_THRESHOLD
        let hasHiddenShoulder = min(leftVisibility, rightVisibility) < OCCLUSION_THRESHOLD
        
        if hasVisibleShoulder && hasHiddenShoulder {
            return visibilityDifference
        } else {
            return 0
        }
    }
    
    // Improved Debug function to print all joint confidences
    func debugPrintOrientation(pose: VNHumanBodyPoseObservation) {
        let orientation = detectOrientation(from: pose)
        let confidence = getSideViewConfidence(pose: pose)
        
        print("\n📐 Orientation Detection:")
        print("   Orientation: \(orientation.description)")
        print("   Is Sideways: \(orientation.isSideways)")
        print("   Confidence: \(String(format: "%.2f", confidence))")
        
        // Debugging shoulder confidences
        if let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
           let rightShoulder = try? pose.recognizedPoint(.rightShoulder) {
            print("   Left Shoulder: \(String(format: "%.2f", leftShoulder.confidence))")
            print("   Right Shoulder: \(String(format: "%.2f", rightShoulder.confidence))")
        }
        
        // Debugging ear confidences
        if let leftEar = try? pose.recognizedPoint(.leftEar),
           let rightEar = try? pose.recognizedPoint(.rightEar) {
            print("   Left Ear: \(String(format: "%.2f", leftEar.confidence))")
            print("   Right Ear: \(String(format: "%.2f", rightEar.confidence))")
        }
    }
}

 
