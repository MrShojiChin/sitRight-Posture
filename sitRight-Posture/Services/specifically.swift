//
//  OrientationDetector.swift
//  sitRight-Posture
//
//  Created by Ryu on 26/9/2568 BE.
//


// OrientationDetector.swift - Put in Services folder
import Vision
import CoreGraphics

/// A class responsible for detecting the orientation of a person from a body pose observation.
class OrientationDetector {
    // Confidence thresholds
    /// The minimum confidence score for a body part to be considered visible.
    private let VISIBILITY_THRESHOLD: Float = 0.5
    /// The maximum confidence score for a body part to be considered occluded or hidden.
    private let OCCLUSION_THRESHOLD: Float = 0.1
    
    /// An enumeration representing the possible orientations of a person.
    enum Orientation {
        /// The person is facing sideways, showing their left profile to the camera.
        case sidewaysLeft
        /// The person is facing sideways, showing their right profile to the camera.
        case sidewaysRight
        /// The person is facing towards the camera.
        case front
        /// The person is facing away from the camera.
        case back
        /// The orientation could not be determined.
        case unknown
        
        /// A boolean value indicating whether the orientation is sideways.
        var isSideways: Bool {
            return self == .sidewaysLeft || self == .sidewaysRight
        }
        
        /// A string description of the orientation.
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
    
    /// Detects the orientation of a person from a given pose.
    /// - Parameter pose: The `VNHumanBodyPoseObservation` to analyze.
    /// - Returns: The detected `Orientation`.
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
    
    /// A simplified check to determine if a person is sideways.
    /// - Parameter pose: The `VNHumanBodyPoseObservation` to analyze.
    /// - Returns: `true` if the person is sideways, `false` otherwise.
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
    
    /// Calculates the confidence score for a side view detection.
    /// - Parameter pose: The `VNHumanBodyPoseObservation` to analyze.
    /// - Returns: A confidence score between 0.0 and 1.0.
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
    
    /// Prints detailed debugging information about the detected orientation and joint confidences.
    /// - Parameter pose: The `VNHumanBodyPoseObservation` to debug.
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
