// CameraViewModel.swift - Put this in ViewModels folder
import SwiftUI
import AVFoundation
import Vision
import Combine

/// A view model that manages the camera, posture analysis, and communicates results to the view.
class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    /// A boolean indicating whether posture analysis is currently in progress.
    @Published var isAnalyzing = false
    /// The result of the most recent posture analysis.
    @Published var analysisResult: AnalysisResult?
    /// The type of posture currently being analyzed.
    @Published var currentPostureType: PostureType?
    /// A boolean indicating if the user is in a correct side view for analysis.
    @Published var isSideView: Bool = false
    /// The confidence score for the detected orientation.
    @Published var orientationConfidence: Float = 0
    /// A message to guide the user to the correct orientation.
    @Published var orientationMessage: String = ""
    
    // MARK: - Camera Manager
    /// The underlying `CameraManager` that handles the camera session and pose detection.
    private let cameraManager = CameraManager()  // Create instance directly, not singleton
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
    /// Sets up Combine subscribers to listen for notifications from the `CameraManager`.
    private func setupBindings() {
        // Listen for analysis completion
        NotificationCenter.default.publisher(for: .postureAnalysisComplete)
            .receive(on: RunLoop.main)
            .compactMap { $0.userInfo }
            .sink { [weak self] userInfo in
                if let angle = userInfo["angle"] as? Double,
                   let type = userInfo["type"] as? PostureType,
                   let isNormal = userInfo["isNormal"] as? Bool,
                   let confidence = userInfo["confidence"] as? Float {
                    self?.handleAnalysisResult(
                        angle: angle,
                        type: type,
                        isNormal: isNormal,
                        confidence: Double(confidence)
                    )
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
    
    /// Initiates the posture analysis process.
    func performAnalysis() {
        isAnalyzing = true
        
        // The actual analysis happens in CameraManager via delegate
        // Simulate delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isAnalyzing = false
        }
    }
    
    // MARK: - Private Methods
    /// Handles the result from a completed posture analysis.
    /// - Parameters:
    ///   - angle: The angle calculated by the analysis.
    ///   - type: The `PostureType` that was analyzed.
    ///   - isNormal: A boolean indicating if the posture is normal.
    ///   - confidence: The confidence score of the analysis.
    private func handleAnalysisResult(angle: Double, type: PostureType, isNormal: Bool, confidence: Double) {
        analysisResult = AnalysisResult(
            angle: angle,
            isNormal: isNormal,
            confidence: confidence
        )
        isSideView = true  // If we got a result, orientation was correct
    }
    
    /// Handles feedback for incorrect user orientation.
    /// - Parameter confidence: The confidence score of the orientation detection.
    private func handleOrientationFeedback(confidence: Float) {
        isSideView = false
        orientationConfidence = confidence
        orientationMessage = "Please turn sideways to the camera"
    }
}

// MARK: - Analysis Result Model
/// A struct representing the result of a posture analysis.
struct AnalysisResult: Equatable {
    /// The angle measured for the posture.
    let angle: Double
    /// A boolean indicating if the posture is within normal range.
    let isNormal: Bool
    /// The confidence score of the analysis.
    let confidence: Double
    
    /// A string describing the status of the posture.
    var status: String {
        isNormal ? "Good Posture" : "Needs Improvement"
    }
    
    /// The color representing the status of the posture.
    var statusColor: Color {
        isNormal ? .green : .orange
    }
}