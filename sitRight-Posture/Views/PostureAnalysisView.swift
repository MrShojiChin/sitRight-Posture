//
//  PostureAnalysisView.swift
//  sitRight-Posture
//
//  Modified for single frame capture and analysis
//

import SwiftUI
import AVFoundation
import Vision
import Combine

// MARK: - Camera Preview Layer (UIViewRepresentable)
struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // Set the connection's video orientation
        DispatchQueue.main.async {
            view.videoPreviewLayer.connection?.videoOrientation = .portrait
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // Update the video orientation if needed
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
        }
    }
}

// MARK: - Main Analysis Selection View
struct PostureAnalysisView: View {
    @State private var selectedAnalysis: PostureType?
    @State private var showCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Clean header with better typography
                Text("Select Analysis Type")
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                // Simplified selection cards with better touch targets
                VStack(spacing: 16) {
                    AnalysisCard(
                        type: .forwardHead,
                        icon: "arrow.up.forward.circle.fill",
                        iconColor: .indigo,
                        isSelected: selectedAnalysis == .forwardHead
                    ) {
                        selectedAnalysis = .forwardHead
                    }
                    
                    AnalysisCard(
                        type: .roundedShoulder,
                        icon: "arrow.left.arrow.right.circle.fill",
                        iconColor: .orange,
                        isSelected: selectedAnalysis == .roundedShoulder
                    ) {
                        selectedAnalysis = .roundedShoulder
                    }
                    
                    AnalysisCard(
                        type: .backSlouch,
                        icon: "arrow.down.circle.fill",
                        iconColor: .pink,
                        isSelected: selectedAnalysis == .backSlouch
                    ) {
                        selectedAnalysis = .backSlouch
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Clean CTA button
                Button(action: {
                    if selectedAnalysis != nil {
                        showCamera = true
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                        Text("Start Analysis")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedAnalysis != nil ? Color.blue : Color.gray.opacity(0.3))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .disabled(selectedAnalysis == nil)
                .animation(.easeInOut(duration: 0.2), value: selectedAnalysis)
            }
            .navigationTitle("Posture Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showCamera) {
            if let analysis = selectedAnalysis {
                SingleFrameCameraView(postureType: analysis)
            }
        }
    }
}

// MARK: - Simplified Analysis Card
struct AnalysisCard: View {
    let type: PostureType
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with subtle background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(type.technicalDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Single Frame Camera View
struct SingleFrameCameraView: View {
    let postureType: PostureType
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CameraViewModel()
    
    // UI State
    @State private var showingResults = false
    @State private var showGuideOverlay = true
    @State private var countdownValue = 0
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Camera preview layer
            CameraPreviewLayer(session: viewModel.session)
                .ignoresSafeArea()
            
            // Gradient overlay for better text visibility
            VStack {
                // Top gradient for header visibility
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                
                Spacer()
                
                // Bottom gradient for controls visibility
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()
            
            // Main UI overlay
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    postureType: postureType,
                    onClose: {
                        viewModel.stopSession()
                        dismiss()
                    }
                )
                .padding(.top, 60)
                
                Spacer()
                
                // Guide overlay
                if showGuideOverlay {
                    GuideOverlay(postureType: postureType)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Instructions and capture controls
                VStack(spacing: 20) {
                    // Instructions
                    InstructionCard(postureType: postureType)
                    
                    // Capture button
                    CaptureButtonWithProgress(
                        isEnabled: !viewModel.isAnalyzing,
                        isAnalyzing: viewModel.isAnalyzing,
                        action: {
                            performCapture()
                        }
                    )
                    .padding(.bottom, 40)
                }
            }
            
            // Countdown overlay
            if countdownValue > 0 {
                CountdownOverlay(value: countdownValue)
            }
            
            // Loading overlay when analyzing
            if viewModel.isAnalyzing && countdownValue == 0 {
                AnalyzingOverlay()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setAnalysisType(postureType)
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onReceive(viewModel.$analysisResultWithImage) { newValue in
            if newValue != nil {
                showingResults = true
            }
        }
        .onReceive(viewModel.$errorMessage) { newValue in
            if newValue != nil {
                showError = true
            }
        }
        .fullScreenCover(isPresented: $showingResults) {
            if let result = viewModel.analysisResultWithImage {
                ImageResultView(result: result)
                    .onDisappear {
                        // Clear result when closing
                        viewModel.clearAnalysisResult()
                    }
            }
        }
        .alert("Analysis Failed", isPresented: $showError) {
            Button("Retry") {
                viewModel.retryCapture()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unable to detect pose. Please ensure you're positioned correctly.")
        }
    }
    
    private func performCapture() {
        // Hide guide overlay
        withAnimation {
            showGuideOverlay = false
        }
        
        // Start countdown
        countdownValue = 3
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    countdownValue -= 1
                }
            } else {
                timer.invalidate()
                countdownValue = 0
                // Capture and analyze
                viewModel.captureAndAnalyze()
            }
        }
    }
}

// MARK: - Header View Component
struct HeaderView: View {
    let postureType: PostureType
    let onClose: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Analysis info
            VStack(alignment: .leading, spacing: 4) {
                Text("Analyzing")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(postureType.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.5))
            )
            
            Spacer()
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Guide Overlay
struct GuideOverlay: View {
    let postureType: PostureType
    @State private var animating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Visual guide
            Image(systemName: "person.fill.turn.right")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6))
                .scaleEffect(animating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animating)
            
            Text("Position yourself sideways")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text(getPositioningTip())
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .onAppear {
            animating = true
        }
    }
    
    private func getPositioningTip() -> String {
        switch postureType {
        case .forwardHead:
            return "Ensure your ear and shoulder are clearly visible from the side"
        case .roundedShoulder:
            return "Stand sideways showing your shoulder profile to the camera"
        case .backSlouch:
            return "Position to show your full spine from the side view"
        }
    }
}

// MARK: - Instruction Card
struct InstructionCard: View {
    let postureType: PostureType
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Positioning Guide")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(getInstruction())
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
        )
        .padding(.horizontal, 30)
    }
    
    private func getInstruction() -> String {
        switch postureType {
        case .forwardHead:
            return "Stand sideways • Keep head natural • Ear and neck visible"
        case .roundedShoulder:
            return "Turn sideways • Relax shoulders • Full upper body in frame"
        case .backSlouch:
            return "Side profile • Stand naturally • Full torso visible"
        }
    }
}

// MARK: - Capture Button with Progress
struct CaptureButtonWithProgress: View {
    let isEnabled: Bool
    let isAnalyzing: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Progress ring when analyzing
                if isAnalyzing {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnalyzing)
                }
                
                // Inner button
                Circle()
                    .fill(isAnalyzing ? Color.blue : Color.white)
                    .frame(width: 65, height: 65)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Icon
                Image(systemName: isAnalyzing ? "waveform" : "camera.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isAnalyzing ? .white : .black)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Countdown Overlay
struct CountdownOverlay: View {
    let value: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            Text("\(value)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10)
                .scaleEffect(1.5)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
        }
    }
}

// MARK: - Analyzing Overlay
struct AnalyzingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated icon
                Image(systemName: "waveform.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("Analyzing Posture...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isAnimating ? 0.3 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Extended PostureType with Display Properties
extension PostureType {
    var displayName: String {
        switch self {
        case .forwardHead:
            return "Forward Head"
        case .roundedShoulder:
            return "Rounded Shoulders"
        case .backSlouch:
            return "Back Slouch"
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .forwardHead:
            return "CVA < 50°"
        case .roundedShoulder:
            return "FSA > 30°"
        case .backSlouch:
            return "Kyphosis > 50°"
        }
    }
    
    var normalRange: String {
        switch self {
        case .forwardHead:
            return "≥ 50°"
        case .roundedShoulder:
            return "≤ 30°"
        case .backSlouch:
            return "≤ 50°"
        }
    }
}
