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

// Single, comprehensive Camera Manager
class CameraManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var permissionGranted = false
    @Published var isSessionRunning = false
    @Published var currentFrame: CVPixelBuffer?
    @Published var detectedPose: VNHumanBodyPoseObservation?
    
    // MARK: - Camera Properties
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
    
    // MARK: - Analysis Properties
    private var currentAnalysisType: PostureType?
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    private let postureAnalyzer = PostureAnalyzer()
    private let orientationDetector = OrientationDetector()  // Add orientation detector
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkPermission()
        setupPoseDetection()
    }
    
    // MARK: - Permission Management
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
    func setAnalysisType(_ type: PostureType) {
        currentAnalysisType = type
    }
    
    // MARK: - Pose Analysis
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
    
    // Helper function for angle calculation (if still needed elsewhere)
    private func calculateCVA(ear: CGPoint, shoulder: CGPoint) -> Double {
        let deltaX = abs(ear.x - shoulder.x)
        let deltaY = abs(ear.y - shoulder.y)
        let angleRadians = atan2(deltaX, deltaY)
        return angleRadians * 180.0 / Double.pi
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
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
    static let postureAnalysisComplete = Notification.Name("postureAnalysisComplete")
    static let orientationIncorrect = Notification.Name("orientationIncorrect")
}
