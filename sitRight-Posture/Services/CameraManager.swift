//
//  CameraManager_Improved.swift
//  sitRight-Posture
//
//  Improved version with better image orientation handling
//

import AVFoundation
import SwiftUI
import Vision
import Combine
import UIKit

/// Manages the camera session, captures single frames, and performs pose detection.
class CameraManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    /// A boolean indicating whether the user has granted camera permission.
    @Published var permissionGranted = false
    /// A boolean indicating whether the camera session is currently running.
    @Published var isSessionRunning = false
    /// The current video frame being processed.
    @Published var currentFrame: CVPixelBuffer?
    /// The analysis result with captured image
    @Published var analysisResultWithImage: AnalysisResultWithImage?
    
    // MARK: - Camera Properties
    /// The capture session that manages the flow of data from the camera.
    let session = AVCaptureSession()
    /// The video data output that processes video frames.
    private let videoOutput = AVCaptureVideoDataOutput()
    /// The dispatch queue on which video frames are processed.
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
    /// The current device orientation
    private var currentOrientation: AVCaptureVideoOrientation = .portrait
    
    // MARK: - Analysis Properties
    /// The current type of posture analysis to be performed.
    private var currentAnalysisType: PostureType?
    /// The analyzer responsible for calculating posture metrics from a pose.
    private let postureAnalyzer = PostureAnalyzer()
    /// The detector responsible for determining device orientation.
    private let orientationDetector = OrientationDetector()
    
    // MARK: - Capture Properties
    /// Flag to indicate if we should capture the next frame
    private var shouldCaptureNextFrame = false
    /// Completion handler for when capture and analysis is complete
    private var captureCompletion: ((Bool) -> Void)?
    
    // MARK: - Initialization
    /// Initializes a new `CameraManager` instance.
    override init() {
        super.init()
        checkPermission()
        setupOrientationObserver()
    }
    
    // MARK: - Orientation Setup
    private func setupOrientationObserver() {
        // Observe device orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func orientationChanged() {
        // Update video orientation based on device orientation
        switch UIDevice.current.orientation {
        case .portrait:
            currentOrientation = .portrait
        case .portraitUpsideDown:
            currentOrientation = .portraitUpsideDown
        case .landscapeLeft:
            currentOrientation = .landscapeRight
        case .landscapeRight:
            currentOrientation = .landscapeLeft
        default:
            break
        }
        
        // Update connection orientation
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentOrientation
            }
        }
    }
    
    // MARK: - Permission Management
    /// Checks the current authorization status for video capture.
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCamera()
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    /// Requests permission from the user to access the camera.
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    self?.setupCamera()
                }
            }
        }
    }
    
    // MARK: - Camera Setup
    /// Configures the camera input and video output for the capture session.
    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Failed to get camera device")
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Failed to create camera input: \(error)")
            session.commitConfiguration()
            return
        }
        
        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            
            // Configure connection
            if let connection = videoOutput.connection(with: .video) {
                connection.isVideoMirrored = true
                connection.videoOrientation = currentOrientation
            }
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - Session Control
    /// Starts the camera capture session.
    func startSession() {
        guard permissionGranted else {
            checkPermission()
            return
        }
        
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                DispatchQueue.main.async {
                    self?.isSessionRunning = true
                }
            }
        }
    }
    
    /// Stops the camera capture session.
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
                DispatchQueue.main.async {
                    self?.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Analysis Type
    /// Sets the type of posture analysis to be performed.
    /// - Parameter type: The `PostureType` to analyze.
    func setAnalysisType(_ type: PostureType) {
        currentAnalysisType = type
    }
    
    // MARK: - Single Frame Capture
    /// Captures a single frame and performs posture analysis on it
    /// - Parameter completion: Callback when capture and analysis is complete
    func captureAndAnalyze(completion: @escaping (Bool) -> Void) {
        guard currentAnalysisType != nil else {
            completion(false)
            return
        }
        
        shouldCaptureNextFrame = true
        captureCompletion = completion
    }
    
    // MARK: - Frame Analysis
    /// Analyzes a captured frame for posture
    private func analyzeFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let analysisType = currentAnalysisType else { return }
        
        // Convert pixel buffer to UIImage for display with correct orientation
        let uiImage = pixelBufferToUIImage(pixelBuffer)
        
        // Create pose detection request
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            if let error = error {
                print("Pose detection error: \(error)")
                self?.captureCompletion?(false)
                return
            }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                print("No pose detected")
                self?.captureCompletion?(false)
                return
            }
            
            // Analyze the pose
            if let analysis = self?.postureAnalyzer.analyze(observation: observation, for: analysisType) {
                // Create result with image
                let result = AnalysisResultWithImage(
                    capturedImage: uiImage,
                    postureType: analysisType,
                    angle: analysis.angle,
                    isNormal: analysis.isNormal,
                    confidence: Double(analysis.confidence),
                    poseObservation: observation,
                    recommendation: analysis.recommendation
                )
                
                DispatchQueue.main.async {
                    self?.analysisResultWithImage = result
                    self?.captureCompletion?(true)
                    
                    // Post notification for backward compatibility
                    NotificationCenter.default.post(
                        name: .postureAnalysisComplete,
                        object: nil,
                        userInfo: [
                            "angle": analysis.angle,
                            "type": analysisType,
                            "isNormal": analysis.isNormal,
                            "confidence": analysis.confidence,
                            "recommendation": analysis.recommendation,
                            "image": uiImage,
                            "result": result
                        ]
                    )
                }
                
                // Debug print
                print("Analysis Complete:")
                print("- Type: \(analysisType.rawValue)")
                print("- Angle: \(analysis.angle)°")
                print("- Normal: \(analysis.isNormal)")
                print("- Confidence: \(analysis.confidence)")
                print("- Severity: \(analysis.severity)")
            } else {
                self?.captureCompletion?(false)
            }
        }
        
        // Perform pose detection with correct orientation
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .upMirrored,  // For front camera with mirroring
            options: [:]
        )
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform pose detection: \(error)")
            captureCompletion?(false)
        }
    }
    
    // MARK: - Helper Methods
    /// Converts CVPixelBuffer to UIImage with correct orientation
    private func pixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply transformations for front camera
        // The front camera is mirrored, and we need to handle the rotation
        let orientedImage = ciImage
            .oriented(.upMirrored)  // Handle front camera mirroring
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(orientedImage, from: orientedImage.extent) else {
            return UIImage()
        }
        
        // Create the final UIImage
        return UIImage(cgImage: cgImage)
    }
    
    /// Alternative method using UIImage orientation
    private func pixelBufferToUIImageAlternative(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage()
        }
        
        // For front camera in portrait mode
        // We need to handle both the mirroring and potential rotation
        // Using .leftMirrored handles both the horizontal flip and 90-degree rotation
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
    }
    
    /// Clears the current analysis result
    func clearAnalysisResult() {
        analysisResultWithImage = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// Called when a new video frame is captured.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Update current frame for preview
        DispatchQueue.main.async {
            self.currentFrame = pixelBuffer
        }
        
        // Check if we should capture this frame for analysis
        if shouldCaptureNextFrame {
            shouldCaptureNextFrame = false
            analyzeFrame(pixelBuffer)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// A notification posted when posture analysis is complete.
    static let postureAnalysisComplete = Notification.Name("postureAnalysisComplete")
    /// A notification posted when the device orientation is incorrect for analysis.
    static let orientationIncorrect = Notification.Name("orientationIncorrect")
}
