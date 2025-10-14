//
//  PostureAnalysisView.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


// PostureAnalysisView.swift - Complete Refactored Version
// Includes all necessary components including CameraPreviewLayer

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
                RefactoredCameraView(postureType: analysis)
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

// MARK: - Refactored Camera View
struct RefactoredCameraView: View {
    let postureType: PostureType
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CameraViewModel()
    
    // UI State
    @State private var showingResults = false
    @State private var showGuideAnimation = true
    @State private var captureInProgress = false
    @State private var countdownValue = 0
    
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
                // Header with proper text visibility
                HeaderView(
                    postureType: postureType,
                    onClose: {
                        viewModel.stopSession()
                        dismiss()
                    }
                )
                .padding(.top, 60)
                
                // Minimal guide overlay
                if showGuideAnimation {
                    MinimalGuideView(postureType: postureType)
                        .transition(.opacity)
                        .onAppear {
                            // Auto-hide guide after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showGuideAnimation = false
                                }
                            }
                        }
                } else {
                    // Positioning indicator when guide is hidden
                    PositioningIndicator(postureType: postureType)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Instructions and capture controls
                VStack(spacing: 20) {
                    // Clear instruction text with proper backdrop
                    InstructionView(
                        postureType: postureType,
                        isPositioned: viewModel.isSideView
                    )
                    
                    // Capture button
                    CaptureButton(
                        isEnabled: !captureInProgress,
                        action: {
                            performCapture()
                        }
                    )
                    .padding(.bottom, 40)
                }
            }
            
            // Countdown overlay
            if countdownValue > 0 {
                CountdownView(value: countdownValue)
            }
        }
        .preferredColorScheme(.dark) // Force dark mode for better camera visibility
        .onAppear {
            viewModel.setAnalysisType(postureType)
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.analysisResult) { _, newValue in
            if newValue != nil {
                showingResults = true
            }
        }
        .sheet(isPresented: $showingResults) {
            if let result = viewModel.analysisResult {
                ResultsView(result: result, postureType: postureType)
            }
        }
    }
    
    private func performCapture() {
        captureInProgress = true
        countdownValue = 3
        
        // Countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                timer.invalidate()
                countdownValue = 0
                viewModel.performAnalysis()
                captureInProgress = false
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
            // Selected analysis type - TOP LEFT as requested
            VStack(alignment: .leading, spacing: 4) {
                Text("Analyzing")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(postureType.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    
                Text(postureType.technicalDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                    )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Minimal Guide View
struct MinimalGuideView: View {
    let postureType: PostureType
    @State private var animateGuide = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Subtle positioning guides
                switch postureType {
                case .forwardHead:
                    ForwardHeadGuide(size: geometry.size, animate: animateGuide)
                case .roundedShoulder:
                    ShoulderGuide(size: geometry.size, animate: animateGuide)
                case .backSlouch:
                    SpineGuide(size: geometry.size, animate: animateGuide)
                }
            }
        }
        .frame(height: 300)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGuide = true
            }
        }
    }
}

// MARK: - Simplified Guide Components
struct ForwardHeadGuide: View {
    let size: CGSize
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Ear position indicator
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 60)
                .position(x: size.width * 0.6, y: size.height * 0.35)
                .overlay(
                    Text("EAR")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .position(x: size.width * 0.6, y: size.height * 0.35)
                )
            
            // Neck position indicator
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 60)
                .position(x: size.width * 0.4, y: size.height * 0.5)
                .overlay(
                    Text("NECK")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .position(x: size.width * 0.4, y: size.height * 0.5)
                )
            
            // Connection line
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.4, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: size.width * 0.6, y: size.height * 0.35))
            }
            .stroke(
                Color.white.opacity(animate ? 0.3 : 0.1),
                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
            )
        }
    }
}

struct ShoulderGuide: View {
    let size: CGSize
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Vertical reference line
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 2, height: size.height)
                .position(x: size.width * 0.5, y: size.height * 0.5)
            
            // Shoulder position
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 80, height: 80)
                .position(x: size.width * 0.5, y: size.height * 0.5)
                .scaleEffect(animate ? 1.1 : 1.0)
        }
    }
}

struct SpineGuide: View {
    let size: CGSize
    let animate: Bool
    
    var body: some View {
        // Spine alignment curve
        Path { path in
            path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.1))
            path.addCurve(
                to: CGPoint(x: size.width * 0.5, y: size.height * 0.9),
                control1: CGPoint(x: size.width * 0.48, y: size.height * 0.3),
                control2: CGPoint(x: size.width * 0.48, y: size.height * 0.7)
            )
        }
        .stroke(
            Color.white.opacity(animate ? 0.5 : 0.3),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 5])
        )
    }
}

// MARK: - Positioning Indicator (shows after guide fades)
struct PositioningIndicator: View {
    let postureType: PostureType
    
    var body: some View {
        VStack {
            Image(systemName: "person.fill.turn.right")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 100)
            
            Text("Turn sideways to camera")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
        }
    }
}

// MARK: - Instruction View
struct InstructionView: View {
    let postureType: PostureType
    let isPositioned: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(isPositioned ? Color.green : Color.yellow)
                    .frame(width: 8, height: 8)
                
                Text(isPositioned ? "Ready to capture" : "Position yourself")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
            )
            
            // Detailed instruction
            Text(getInstruction())
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func getInstruction() -> String {
        switch postureType {
        case .forwardHead:
            return "Stand sideways with ear and neck visible"
        case .roundedShoulder:
            return "Turn to show your shoulder profile"
        case .backSlouch:
            return "Position to show your spine from side"
        }
    }
}

// MARK: - Capture Button
struct CaptureButton: View {
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Inner button
                Circle()
                    .fill(Color.white)
                    .frame(width: 65, height: 65)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.black)
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

// MARK: - Countdown View
struct CountdownView: View {
    let value: Int
    
    var body: some View {
        Text("\(value)")
            .font(.system(size: 120, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 10)
            .scaleEffect(1.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
    }
}

// MARK: - Results View
struct ResultsView: View {
    let result: AnalysisResult
    let postureType: PostureType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Result icon
                Image(systemName: result.isNormal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(result.statusColor)
                    .padding(.top, 40)
                
                // Status
                VStack(spacing: 8) {
                    Text(result.status)
                        .font(.system(size: 32, weight: .bold))
                    
                    Text(postureType.displayName)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                // Metrics
                VStack(spacing: 20) {
                    MetricRow(
                        label: "Measured Angle",
                        value: "\(Int(result.angle))°",
                        color: result.statusColor
                    )
                    
                    MetricRow(
                        label: "Normal Range",
                        value: postureType.normalRange,
                        color: .secondary
                    )
                    
                    MetricRow(
                        label: "Confidence",
                        value: "\(Int(result.confidence * 100))%",
                        color: .blue
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Recommendation
                VStack(spacing: 16) {
                    Text("Recommendation")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(getRecommendation())
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func getRecommendation() -> String {
        if result.isNormal {
            return "Your \(postureType.displayName.lowercased()) is within the normal range. Keep maintaining good posture!"
        } else {
            switch postureType {
            case .forwardHead:
                return "Try chin tucks and ensure your screen is at eye level to improve head positioning."
            case .roundedShoulder:
                return "Practice shoulder blade squeezes and doorway stretches to correct shoulder position."
            case .backSlouch:
                return "Strengthen your core and consider using lumbar support while sitting."
            }
        }
    }
}

// MARK: - Metric Row Component
struct MetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
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
