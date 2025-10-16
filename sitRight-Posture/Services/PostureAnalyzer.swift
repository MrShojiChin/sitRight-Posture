//
//  PostureAnalyzer.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


// PostureAnalyzer.swift - Put in Services folder
import Vision
import CoreGraphics
import UIKit

/// A class that analyzes `VNHumanBodyPoseObservation` to detect various posture issues.
class PostureAnalyzer {
    
    // MARK: - Analysis Result
    /// A struct containing the detailed results of a posture analysis.
    struct DetailedAnalysis {
        /// The type of posture that was analyzed.
        let postureType: PostureType
        /// The calculated angle for the specific posture type.
        let angle: Double
        /// A boolean indicating if the posture is considered normal.
        let isNormal: Bool
        /// The confidence score of the analysis, based on the visibility of key body points.
        let confidence: Float
        /// A dictionary of the key body points used in the analysis.
        let keyPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
        
        /// A string describing the severity of the posture issue.
        var severity: String {
            switch postureType {
            case .forwardHead:
                if angle >= 50 { return "normal" }
                else if angle >= 45 { return "mild" }
                else { return "moderate to severe" }
            case .roundedShoulder:
                if angle < 30 { return "normal" }
                else if angle < 40 { return "mild" }
                else { return "moderate to severe" }
            case .backSlouch:
                if angle <= 50 { return "normal" }
                else if angle <= 60 { return "mild" }
                else { return "moderate to severe" }
            }
        }
        
        /// A recommendation to help correct the posture issue.
        var recommendation: String {
            switch postureType {
            case .forwardHead:
                if isNormal {
                    return "Good head position! Maintain this alignment."
                } else if severity == "mild" {
                    return "Mild forward head detected (CVA: \(String(format: "%.1f", angle))°). Try chin tucks and ensure your screen is at eye level."
                } else {
                    return "Significant forward head posture (CVA: \(String(format: "%.1f", angle))°). Focus on strengthening neck muscles with chin tucks and adjust your workstation ergonomics."
                }
            case .roundedShoulder:
                if isNormal {
                    return "Shoulders are well aligned! Keep up the good posture."
                } else if severity == "mild" {
                    return "Mild shoulder rounding detected (FSA: \(String(format: "%.1f", angle))°). Practice shoulder blade squeezes and doorway stretches."
                } else {
                    return "Significant shoulder rounding (FSA: \(String(format: "%.1f", angle))°). Focus on chest stretches and upper back strengthening exercises."
                }
            case .backSlouch:
                if isNormal {
                    return "Good back posture! Maintain this position."
                } else if severity == "mild" {
                    return "Mild slouching detected. Engage your core and sit up straight."
                } else {
                    return "Significant slouching detected. Strengthen your core and consider lumbar support."
                }
            }
        }
    }
    
    // MARK: - Main Analysis Function
    /// Analyzes a pose observation for a specific posture type.
    /// - Parameters:
    ///   - observation: The `VNHumanBodyPoseObservation` to analyze.
    ///   - type: The `PostureType` to check for.
    /// - Returns: A `DetailedAnalysis` object if the analysis is successful, otherwise `nil`.
    func analyze(observation: VNHumanBodyPoseObservation, for type: PostureType) -> DetailedAnalysis? {
        switch type {
        case .forwardHead:
            return analyzeForwardHead(observation)
        case .roundedShoulder:
            return analyzeRoundedShoulders(observation)
        case .backSlouch:
            return analyzeBackSlouch(observation)
        }
    }
    
    // MARK: - Forward Head Posture Analysis
    /// Analyzes the observation for Forward Head Posture (FHP).
    /// - Parameter observation: The `VNHumanBodyPoseObservation` to analyze.
    /// - Returns: A `DetailedAnalysis` for FHP, or `nil` if key points are not visible.
    private func analyzeForwardHead(_ observation: VNHumanBodyPoseObservation) -> DetailedAnalysis? {
        do {
            // Get required points
            let rightEar = try observation.recognizedPoint(.rightEar)
            let leftEar = try observation.recognizedPoint(.leftEar)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let neck = try observation.recognizedPoint(.neck)
            
            // Check confidence
            let minConfidence: Float = 0.5
            guard rightEar.confidence > minConfidence,
                  leftEar.confidence > minConfidence,
                  rightShoulder.confidence > minConfidence,
                  leftShoulder.confidence > minConfidence else {
                print("Low confidence in key points for FHP analysis")
                return nil
            }
            
            // Calculate midpoints for more stable measurement
            let earMidpoint = CGPoint(
                x: (rightEar.location.x + leftEar.location.x) / 2,
                y: (rightEar.location.y + leftEar.location.y) / 2
            )
            
            let shoulderMidpoint = CGPoint(
                x: (rightShoulder.location.x + leftShoulder.location.x) / 2,
                y: (rightShoulder.location.y + leftShoulder.location.y) / 2
            )
            
            // Calculate Craniovertebral Angle (CVA)
            let cva = calculateCraniovertebralAngle(ear: earMidpoint, shoulder: shoulderMidpoint)
            
            // Determine if posture is normal (CVA >= 50 degrees is normal)
            let isNormal = cva >= 50.0
            
            // Average confidence
            let avgConfidence = (rightEar.confidence + leftEar.confidence +
                               rightShoulder.confidence + leftShoulder.confidence) / 4
            
            return DetailedAnalysis(
                postureType: .forwardHead,
                angle: cva,
                isNormal: isNormal,
                confidence: avgConfidence,
                keyPoints: [
                    .rightEar: rightEar,
                    .leftEar: leftEar,
                    .rightShoulder: rightShoulder,
                    .leftShoulder: leftShoulder,
                    .neck: neck
                ]
            )
            
        } catch {
            print("Error getting body points for FHP analysis: \(error)")
            return nil
        }
    }
    
    // MARK: - Rounded Shoulders Analysis
    /// Analyzes the observation for rounded shoulders.
    /// - Parameter observation: The `VNHumanBodyPoseObservation` to analyze.
    /// - Returns: A `DetailedAnalysis` for rounded shoulders, or `nil` if key points are not visible.
    private func analyzeRoundedShoulders(_ observation: VNHumanBodyPoseObservation) -> DetailedAnalysis? {
        do {
            // Get required points
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightHip = try observation.recognizedPoint(.rightHip)
            let leftHip = try observation.recognizedPoint(.leftHip)
            let neck = try observation.recognizedPoint(.neck)
            
            // Check confidence
            let minConfidence: Float = 0.5
            guard rightShoulder.confidence > minConfidence,
                  leftShoulder.confidence > minConfidence,
                  rightHip.confidence > minConfidence,
                  leftHip.confidence > minConfidence else {
                return nil
            }
            
            // Calculate shoulder forward angle
            let shoulderMidpoint = CGPoint(
                x: (rightShoulder.location.x + leftShoulder.location.x) / 2,
                y: (rightShoulder.location.y + leftShoulder.location.y) / 2
            )
            
            let hipMidpoint = CGPoint(
                x: (rightHip.location.x + leftHip.location.x) / 2,
                y: (rightHip.location.y + leftHip.location.y) / 2
            )
            
            // Calculate forward projection angle
            let shoulderAngle = calculateShoulderFlexion(shoulder: shoulderMidpoint, hip: hipMidpoint)
            
            // Normal is <= 30 degrees
            let isNormal = shoulderAngle <= 30.0
            
            let avgConfidence = (rightShoulder.confidence + leftShoulder.confidence +
                               rightHip.confidence + leftHip.confidence) / 4
            
            return DetailedAnalysis(
                postureType: .roundedShoulder,
                angle: shoulderAngle,
                isNormal: isNormal,
                confidence: avgConfidence,
                keyPoints: [
                    .rightShoulder: rightShoulder,
                    .leftShoulder: leftShoulder,
                    .rightHip: rightHip,
                    .leftHip: leftHip,
                    .neck: neck
                ]
            )
            
        } catch {
            print("Error analyzing rounded shoulders: \(error)")
            return nil
        }
    }
    
    // MARK: - Back Slouch Analysis
    /// Analyzes the observation for back slouch (thoracic kyphosis).
    /// - Parameter observation: The `VNHumanBodyPoseObservation` to analyze.
    /// - Returns: A `DetailedAnalysis` for back slouch, or `nil` if key points are not visible.
    private func analyzeBackSlouch(_ observation: VNHumanBodyPoseObservation) -> DetailedAnalysis? {
        do {
            // Get spine-related points
            let neck = try observation.recognizedPoint(.neck)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightHip = try observation.recognizedPoint(.rightHip)
            let leftHip = try observation.recognizedPoint(.leftHip)
            let root = try observation.recognizedPoint(.root)
            
            // Check confidence
            let minConfidence: Float = 0.5
            guard neck.confidence > minConfidence,
                  rightShoulder.confidence > minConfidence,
                  leftShoulder.confidence > minConfidence,
                  root.confidence > minConfidence else {
                return nil
            }
            
            let shoulderMidpoint = CGPoint(
                x: (rightShoulder.location.x + leftShoulder.location.x) / 2,
                y: (rightShoulder.location.y + leftShoulder.location.y) / 2
            )
            
            let hipMidpoint = CGPoint(
                x: (rightHip.location.x + leftHip.location.x) / 2,
                y: (rightHip.location.y + leftHip.location.y) / 2
            )
            
            // Calculate thoracic kyphosis angle
            let kyphosisAngle = calculateThoracicKyphosis(
                neck: neck.location,
                midSpine: shoulderMidpoint,
                lowerSpine: hipMidpoint
            )
            
            // Normal is <= 50 degrees
            let isNormal = kyphosisAngle <= 50.0
            
            let avgConfidence = (neck.confidence + rightShoulder.confidence +
                               leftShoulder.confidence + root.confidence) / 4
            
            return DetailedAnalysis(
                postureType: .backSlouch,
                angle: kyphosisAngle,
                isNormal: isNormal,
                confidence: avgConfidence,
                keyPoints: [
                    .neck: neck,
                    .rightShoulder: rightShoulder,
                    .leftShoulder: leftShoulder,
                    .rightHip: rightHip,
                    .leftHip: leftHip,
                    .root: root
                ]
            )
            
        } catch {
            print("Error analyzing back slouch: \(error)")
            return nil
        }
    }
    
    // MARK: - Angle Calculations
    
    /// Calculates the Craniovertebral Angle (CVA) to detect forward head posture.
    /// This implementation calculates the angle of the line connecting the ear and shoulder with the vertical axis, then converts it to be relative to the horizontal axis.
    /// - Parameters:
    ///   - ear: The midpoint of the ears.
    ///   - shoulder: The midpoint of the shoulders.
    /// - Returns: The calculated angle in degrees. A normal CVA is typically >= 50 degrees.
    private func calculateCraniovertebralAngle(ear: CGPoint, shoulder: CGPoint) -> Double {
        // CVA is the angle between a vertical line through the shoulder
        // and a line connecting the ear to the shoulder
        
        // Convert Vision coordinates (0,0 at bottom-left) to standard (0,0 at top-left)
        let ear_adjusted = CGPoint(x: ear.x, y: 1.0 - ear.y)
        let shoulder_adjusted = CGPoint(x: shoulder.x, y: 1.0 - shoulder.y)
        
        // Calculate horizontal distance (forward projection)
        let horizontalDistance = abs(ear_adjusted.x - shoulder_adjusted.x)
        
        // Calculate vertical distance
        let verticalDistance = abs(ear_adjusted.y - shoulder_adjusted.y)
        
        // Calculate angle from vertical
        let angleRadians = atan2(horizontalDistance, verticalDistance)
        let angleDegrees = angleRadians * 180.0 / Double.pi
        
        // Return CVA. The calculation converts the angle from the vertical to the angle from the horizontal.
        return 90.0 - angleDegrees
    }
    
    /// Calculates the shoulder flexion angle to detect rounded shoulders.
    /// This is a simplified estimation based on the horizontal displacement of shoulders relative to hips.
    /// - Parameters:
    ///   - shoulder: The midpoint of the shoulders.
    ///   - hip: The midpoint of the hips.
    /// - Returns: An estimated angle in degrees. A normal angle is typically <= 30 degrees.
    private func calculateShoulderFlexion(shoulder: CGPoint, hip: CGPoint) -> Double {
        // Calculate how far forward the shoulders are relative to hips
        
        // In profile view, x-difference indicates forward/backward position
        let forwardDistance = abs(shoulder.x - hip.x)
        
        // Estimate angle based on normalized distance
        // This is a simplified calculation - adjust based on testing
        let angle = forwardDistance * 180.0  // Scale to degrees
        
        return min(angle, 90.0)  // Cap at 90 degrees
    }
    
    /// Calculates the thoracic kyphosis angle to detect back slouch.
    /// - Parameters:
    ///   - neck: The location of the neck joint.
    ///   - midSpine: The midpoint of the shoulders, used as an approximation for the mid-spine.
    ///   - lowerSpine: The midpoint of the hips, used as an approximation for the lower spine.
    /// - Returns: The angle of the spine's curvature in degrees. A normal angle is typically <= 50 degrees.
    private func calculateThoracicKyphosis(neck: CGPoint, midSpine: CGPoint, lowerSpine: CGPoint) -> Double {
        // Calculate the angle of spine curvature
        
        // Create vectors
        let v1 = CGVector(dx: neck.x - midSpine.x, dy: neck.y - midSpine.y)
        let v2 = CGVector(dx: lowerSpine.x - midSpine.x, dy: lowerSpine.y - midSpine.y)
        
        // Calculate angle between vectors
        let dotProduct = v1.dx * v2.dx + v1.dy * v2.dy
        let magnitude1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let magnitude2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let angleRadians = acos(max(-1, min(1, cosAngle)))  // Clamp to valid range
        let angleDegrees = angleRadians * 180.0 / Double.pi
        
        // Return the deviation from straight (180 degrees)
        return abs(180.0 - angleDegrees)
    }
    
    // MARK: - Helper Functions
    
    /// Prints the confidence and location of key joints from a pose observation for debugging purposes.
    /// - Parameter observation: The `VNHumanBodyPoseObservation` containing the joints to print.
    func debugPrintKeyPoints(_ observation: VNHumanBodyPoseObservation) {
        let joints: [VNHumanBodyPoseObservation.JointName] = [
            .neck, .rightShoulder, .leftShoulder,
            .rightElbow, .leftElbow, .rightWrist, .leftWrist,
            .rightHip, .leftHip, .root
        ]
        
        print("\n=== Detected Key Points ===")
        for joint in joints {
            if let point = try? observation.recognizedPoint(joint) {
                print("\(joint.rawValue): confidence=\(point.confidence), location=(\(point.location.x), \(point.location.y))")
            }
        }
        print("========================\n")
    }
}
