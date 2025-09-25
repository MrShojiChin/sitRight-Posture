// CameraViewModel.swift - Put this in ViewModels folder
import SwiftUI
import AVFoundation
import Vision
import Combine

class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var analysisResult: AnalysisResult?
    @Published var currentPostureType: PostureType?
    @Published var isSideView: Bool = false
    @Published var orientationConfidence: Float = 0
    @Published var orientationMessage: String = ""
    
    // MARK: - Camera Manager
    private let cameraManager = CameraManager()  // Create instance directly, not singleton
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var session: AVCaptureSession {
        return cameraManager.session
    }
    
    var isSessionRunning: Bool {
        return cameraManager.isSessionRunning
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
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
    func startSession() {
        cameraManager.startSession()
    }
    
    func stopSession() {
        cameraManager.stopSession()
    }
    
    func setAnalysisType(_ type: PostureType) {
        currentPostureType = type
        cameraManager.setAnalysisType(type)
    }
    
    func performAnalysis() {
        isAnalyzing = true
        
        // The actual analysis happens in CameraManager via delegate
        // Simulate delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isAnalyzing = false
        }
    }
    
    // MARK: - Private Methods
    private func handleAnalysisResult(angle: Double, type: PostureType, isNormal: Bool, confidence: Double) {
        analysisResult = AnalysisResult(
            angle: angle,
            isNormal: isNormal,
            confidence: confidence
        )
        isSideView = true  // If we got a result, orientation was correct
    }
    
    private func handleOrientationFeedback(confidence: Float) {
        isSideView = false
        orientationConfidence = confidence
        orientationMessage = "Please turn sideways to the camera"
    }
}

// MARK: - Analysis Result Model
struct AnalysisResult: Equatable {
    let angle: Double
    let isNormal: Bool
    let confidence: Double
    
    var status: String {
        isNormal ? "Good Posture" : "Needs Improvement"
    }
    
    var statusColor: Color {
        isNormal ? .green : .orange
    }
}
