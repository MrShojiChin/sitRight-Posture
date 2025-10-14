//
//  CameraViewModel.swift
//  sitRight-Posture
//
//  Modified to handle single frame capture and analysis
//

import SwiftUI
import AVFoundation
import Vision
import Combine

/// A view model that manages the camera, single frame capture, and posture analysis.
class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    /// A boolean indicating whether posture analysis is currently in progress.
    @Published var isAnalyzing = false
    /// The result of the most recent posture analysis with image.
    @Published var analysisResultWithImage: AnalysisResultWithImage?
    /// The type of posture currently being analyzed.
    @Published var currentPostureType: PostureType?
    /// A boolean indicating if the capture was successful
    @Published var captureSuccessful = false
    /// An error message if capture fails
    @Published var errorMessage: String?
    
    // MARK: - Camera Manager
    /// The underlying `CameraManager` that handles the camera session and pose detection.
    private let cameraManager = CameraManager()
    /// A set to store Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    /// The `AVCaptureSession` from the `CameraManager`.
    var session: AVCaptureSession {
        return cameraManager.session
    }
    
    /// A boolean indicating if the camera session is running.
    var isSessionRunning: Bool {
        return cameraManager.isSessionRunning
    }
    
    // MARK: - Initialization
    /// Initializes the view model and sets up bindings.
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    /// Sets up Combine subscribers to listen for updates from the `CameraManager`.
    private func setupBindings() {
        // Listen for analysis results from CameraManager
        cameraManager.$analysisResultWithImage
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.analysisResultWithImage = result
                if result != nil {
                    self?.captureSuccessful = true
                }
            }
            .store(in: &cancellables)
        
        // Listen for analysis completion notification
        NotificationCenter.default.publisher(for: .postureAnalysisComplete)
            .receive(on: RunLoop.main)
            .compactMap { $0.userInfo }
            .sink { [weak self] userInfo in
                // Handle the notification if needed
                if let result = userInfo["result"] as? AnalysisResultWithImage {
                    self?.handleAnalysisComplete(result)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    /// Starts the camera session.
    func startSession() {
        cameraManager.startSession()
    }
    
    /// Stops the camera session.
    func stopSession() {
        cameraManager.stopSession()
    }
    
    /// Sets the type of posture to be analyzed.
    /// - Parameter type: The `PostureType` to analyze.
    func setAnalysisType(_ type: PostureType) {
        currentPostureType = type
        cameraManager.setAnalysisType(type)
    }
    
    /// Captures a single frame and performs posture analysis.
    func captureAndAnalyze() {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        errorMessage = nil
        captureSuccessful = false
        
        // Perform single frame capture and analysis
        cameraManager.captureAndAnalyze { [weak self] success in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                
                if !success {
                    self?.errorMessage = "Unable to detect pose. Please ensure you're positioned correctly and try again."
                    self?.captureSuccessful = false
                } else {
                    self?.captureSuccessful = true
                }
            }
        }
    }
    
    /// Clears the current analysis result
    func clearAnalysisResult() {
        analysisResultWithImage = nil
        captureSuccessful = false
        errorMessage = nil
        cameraManager.clearAnalysisResult()
    }
    
    /// Retries the capture and analysis
    func retryCapture() {
        clearAnalysisResult()
        captureAndAnalyze()
    }
    
    // MARK: - Private Methods
    /// Handles the completion of analysis
    private func handleAnalysisComplete(_ result: AnalysisResultWithImage) {
        // Any additional processing after analysis completes
        print("Analysis complete for \(result.postureType.rawValue)")
        print("Status: \(result.status)")
        print("Severity: \(result.severity)")
    }
}
