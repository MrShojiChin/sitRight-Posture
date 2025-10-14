//
//  CameraManager.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//

// CameraManager.swift - Put this in Services folder
import AVFoundation
import SwiftUI
import Vision
import Combine

/// Manages the camera session, captures video frames, and performs pose detection.
class CameraManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    /// A boolean indicating whether the user has granted camera permission.
    @Published var permissionGranted = false
    /// A boolean indicating whether the camera session is currently running.
    @Published var isSessionRunning = false
    /// The current video frame being processed.
    @Published var currentFrame: CVPixelBuffer?
    /// The most recently detected human body pose observation.
    @Published var detectedPose: VNHumanBodyPoseObservation?
    
    // MARK: - Camera Properties
    /// The capture session that manages the flow of data from the camera.
    let session = AVCaptureSession()
    /// The video data output that processes video frames.
    private let videoOutput = AVCaptureVideoDataOutput()
    /// The dispatch queue on which video frames are processed.
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
    
    // MARK: - Analysis Properties
    /// The current type of posture analysis to be performed.
    private var currentAnalysisType: PostureType?
    /// The request to detect a human body pose in an image.
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    /// The analyzer responsible for calculating posture metrics from a pose.
    private let postureAnalyzer = PostureAnalyzer()
    /// The detector responsible for determining device orientation.
    private let orientationDetector = OrientationDetector()
    
    // MARK: - Initialization
    /// Initializes a new `CameraManager` instance.
    override init() {
        super.init()
        checkPermission()
        setupPoseDetection()
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
                connection.videoOrientation = .portrait
            }
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - Pose Detection Setup
    /// Sets up the Vision request for human body pose detection.
    private func setupPoseDetection() {
        poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            if let error = error {
                print("Pose detection error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else { return }
            
            DispatchQueue.main.async {
                self?.detectedPose = observation
                self?.analyzePose(observation)
            }
        }
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
    
    // MARK: - Pose Analysis
    /// Analyzes the detected pose for the specified posture type.
    /// - Parameter observation: The `VNHumanBodyPoseObservation` to analyze.
    private func analyzePose(_ observation: VNHumanBodyPoseObservation) {
        guard let analysisType = currentAnalysisType else { return }
        
        // Use the real analyzer
        if let analysis = postureAnalyzer.analyze(observation: observation, for: analysisType) {
            // Post notification with detailed result
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .postureAnalysisComplete,
                    object: nil,
                    userInfo: [
                        "angle": analysis.angle,
                        "type": analysisType,
                        "isNormal": analysis.isNormal,
                        "confidence": analysis.confidence,
                        "recommendation": analysis.recommendation
                    ]
                )
            }
            
            // Debug print
            print("Analysis Result: \(analysisType.rawValue)")
            print("Angle: \(analysis.angle)°")
            print("Normal: \(analysis.isNormal)")
            print("Confidence: \(analysis.confidence)")
            print("Recommendation: \(analysis.recommendation)")
            
            // Debug print key points
            postureAnalyzer.debugPrintKeyPoints(observation)
        }
    }
    
    /// Calculates the Craniovertebral Angle (CVA).
    /// - Parameters:
    ///   - ear: The position of the ear.
    ///   - shoulder: The position of the shoulder.
    /// - Returns: The calculated CVA in degrees.
    private func calculateCVA(ear: CGPoint, shoulder: CGPoint) -> Double {
        let deltaX = abs(ear.x - shoulder.x)
        let deltaY = abs(ear.y - shoulder.y)
        let angleRadians = atan2(deltaX, deltaY)
        return angleRadians * 180.0 / Double.pi
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// Called when a new video frame is captured.
    /// - Parameters:
    ///   - output: The capture output that produced the frame.
    ///   - sampleBuffer: The `CMSampleBuffer` containing the video frame.
    ///   - connection: The connection from which the video frame was received.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Store current frame
        DispatchQueue.main.async {
            self.currentFrame = pixelBuffer
        }
        
        // Perform pose detection if request exists
        if let request = poseRequest {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform pose detection: \(error)")
            }
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