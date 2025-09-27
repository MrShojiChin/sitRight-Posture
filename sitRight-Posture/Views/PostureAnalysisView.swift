//
//  PostureAnalysisView.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


// PostureAnalysisView.swift - Step 1: Basic Structure
import SwiftUI
import AVFoundation

/// A view that allows users to select a type of posture analysis to perform.
struct PostureAnalysisView: View {
    /// The currently selected posture analysis type.
    @State private var selectedAnalysis: PostureType?
    /// A boolean to control the presentation of the camera view.
    @State private var showCamera = false
    
    /// The body of the `PostureAnalysisView`.
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Select an area to analyze")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                // Simple Cards (without complex animations first)
                VStack(spacing: 15) {
                    // Forward Head Card
                    Button(action: { selectedAnalysis = .forwardHead }) {
                        HStack {
                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading) {
                                Text("Forward Head Posture")
                                    .font(.headline)
                                Text("CVA < 50°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Rounded Shoulders Card
                    Button(action: { selectedAnalysis = .roundedShoulder }) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Rounded Shoulders")
                                    .font(.headline)
                                Text("FSA > 30°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Back Slouch Card
                    Button(action: { selectedAnalysis = .backSlouch }) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.pink)
                            
                            VStack(alignment: .leading) {
                                Text("Back Slouch")
                                    .font(.headline)
                                Text("Kyphosis > 50°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Selected indicator
                if let selected = selectedAnalysis {
                    Text("Selected: \(selected.rawValue)")
                        .foregroundColor(.blue)
                }
                
                // Start Button
                Button(action: {
                    if selectedAnalysis != nil {
                        showCamera = true
                    }
                }) {
                    Text("Start Analysis")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAnalysis != nil ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(selectedAnalysis == nil)
            }
            .navigationTitle("Posture Analysis")
        }
        .sheet(isPresented: $showCamera) {
            // Simple placeholder for now
            SimpleCameraView(postureType: selectedAnalysis ?? .forwardHead)
        }
    }
}

/// A view that displays the camera feed and guides the user for posture analysis.
struct SimpleCameraView: View {
    /// The type of posture to be analyzed.
    let postureType: PostureType
    /// The presentation mode environment variable to dismiss the view.
    @Environment(\.dismiss) var dismiss
    /// The view model that manages camera operations.
    @StateObject private var viewModel = CameraViewModel()
    /// A boolean to control the presentation of the results view.
    @State private var showingResults = false
    
    /// The body of the `SimpleCameraView`.
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreviewLayer(session: viewModel.session)
                    .edgesIgnoringSafeArea(.all)
                
                // Dark overlay for better visibility
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Top bar
                    HStack {
                        Button(action: {
                            viewModel.stopSession()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Spacer()
                        
                        Text(postureType.rawValue)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Add the guide overlay based on posture type
                    PostureGuideOverlay(postureType: postureType)
                        .frame(height: 300)
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "person.fill.turn.right")
                            Text("TURN SIDEWAYS")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.yellow)
                        .padding(10)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        
                        Text(getInstructions())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Analyze button
                    Button(action: {
                        print("Analyzing: \(postureType.rawValue)")
                        viewModel.performAnalysis()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.setAnalysisType(postureType)
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onReceive(viewModel.$analysisResult) { result in
            if result != nil {
                showingResults = true
            }
        }
        .sheet(isPresented: $showingResults) {
            if let result = viewModel.analysisResult {
                SimpleResultView(result: result, postureType: postureType)
            }
        }
    }
    
    /// Returns the appropriate instruction string for the selected posture type.
    /// - Returns: A string containing user instructions.
    private func getInstructions() -> String {
        switch postureType {
        case .forwardHead:
            return "Position ear and neck in the circles"
        case .roundedShoulder:
            return "Align C7 and shoulder with markers"
        case .backSlouch:
            return "Keep spine visible from neck to hip"
        }
    }
}

/// A view that displays a specific guide overlay based on the posture type.
struct PostureGuideOverlay: View {
    /// The type of posture for which to display a guide.
    let postureType: PostureType
    
    /// The body of the `PostureGuideOverlay`.
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch postureType {
                case .forwardHead:
                    CVAGuideView(size: geometry.size)
                case .roundedShoulder:
                    FSAGuideView(size: geometry.size)
                case .backSlouch:
                    SpineGuideView(size: geometry.size)
                }
            }
        }
    }
}

/// A guide view for analyzing rounded shoulders (Forward Shoulder Angle).
struct FSAGuideView: View {
    /// The size of the parent view.
    let size: CGSize
    
    /// The body of the `FSAGuideView`.
    var body: some View {
        ZStack {
            // Vertical reference line through C7
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.5, y: 0))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
            }
            .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
            
            // C7 marker
            Circle()
                .fill(Color.orange)
                .frame(width: 20, height: 20)
                .position(x: size.width * 0.5, y: size.height * 0.4)
            
            Text("C7")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.orange)
                .cornerRadius(4)
                .position(x: size.width * 0.5 - 40, y: size.height * 0.4)
            
            // Acromion marker
            Circle()
                .fill(Color.orange)
                .frame(width: 20, height: 20)
                .position(x: size.width * 0.65, y: size.height * 0.5)
            
            Text("Shoulder")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.orange)
                .cornerRadius(4)
                .position(x: size.width * 0.65 + 50, y: size.height * 0.5)
            
            // FSA angle line
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.4))
                path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.5))
            }
            .stroke(Color.red, lineWidth: 2)
            
            // Angle arc
            Path { path in
                path.addArc(
                    center: CGPoint(x: size.width * 0.5, y: size.height * 0.4),
                    radius: 40,
                    startAngle: .degrees(270),
                    endAngle: .degrees(315),
                    clockwise: false
                )
            }
            .stroke(Color.red, lineWidth: 2)
            
            Text("FSA")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .position(x: size.width * 0.5 + 25, y: size.height * 0.35)
        }
    }
}

/// A guide view for analyzing forward head posture (Craniovertebral Angle).
struct CVAGuideView: View {
    /// The size of the parent view.
    let size: CGSize
    
    /// The body of the `CVAGuideView`.
    var body: some View {
        ZStack {
            // Horizontal line through C7
            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: size.width, y: size.height * 0.5))
            }
            .stroke(Color.yellow.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
            
            // C7/Neck marker
            Circle()
                .fill(Color.purple)
                .frame(width: 20, height: 20)
                .position(x: size.width * 0.4, y: size.height * 0.5)
            
            Text("Neck")
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.purple)
                .cornerRadius(4)
                .position(x: size.width * 0.4, y: size.height * 0.6)
            
            // Ear marker
            Circle()
                .fill(Color.purple)
                .frame(width: 20, height: 20)
                .position(x: size.width * 0.6, y: size.height * 0.35)
            
            Text("Ear")
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.purple)
                .cornerRadius(4)
                .position(x: size.width * 0.6, y: size.height * 0.25)
            
            // CVA angle line
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.4, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: size.width * 0.6, y: size.height * 0.35))
            }
            .stroke(Color.green, lineWidth: 2)
        }
    }
}

/// A guide view for analyzing back slouch.
struct SpineGuideView: View {
    /// The size of the parent view.
    let size: CGSize
    
    /// The body of the `SpineGuideView`.
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.2))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                    control1: CGPoint(x: size.width * 0.45, y: size.height * 0.4),
                    control2: CGPoint(x: size.width * 0.45, y: size.height * 0.6)
                )
            }
            .stroke(Color.pink, style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
            
            Text("Align spine with curve")
                .font(.caption)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.pink)
                .cornerRadius(8)
                .position(x: size.width * 0.5, y: size.height * 0.9)
        }
    }
}

/// A view to display the results of a posture analysis.
struct SimpleResultView: View {
    /// The result of the analysis.
    let result: AnalysisResult
    /// The type of posture that was analyzed.
    let postureType: PostureType
    /// The presentation mode environment variable to dismiss the view.
    @Environment(\.dismiss) var dismiss
    
    /// The body of the `SimpleResultView`.
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: result.isNormal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(result.isNormal ? .green : .orange)
                
                Text(result.status)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Angle: \(Int(result.angle))°")
                    .font(.title)
                
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .foregroundColor(.secondary)
                
                Button("Done") {
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Results")
        }
    }
}

/// A `UIViewRepresentable` that displays the video feed from an `AVCaptureSession`.
struct CameraPreviewLayer: UIViewRepresentable {
    /// The `AVCaptureSession` to display.
    let session: AVCaptureSession
    
    /// Creates the `UIView` for the representable.
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    /// Updates the `UIView`.
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}