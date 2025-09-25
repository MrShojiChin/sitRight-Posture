//
//  PostureAnalysisView.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//


// PostureAnalysisView.swift - Step 1: Basic Structure
import SwiftUI
import AVFoundation

struct PostureAnalysisView: View {
    @State private var selectedAnalysis: PostureType?
    @State private var showCamera = false
    
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

// Camera View with proper guides
struct SimpleCameraView: View {
    let postureType: PostureType
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingResults = false
    
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

// Guide Overlay
struct PostureGuideOverlay: View {
    let postureType: PostureType
    
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

// FSA Guide for Rounded Shoulders (matching your diagram)
struct FSAGuideView: View {
    let size: CGSize
    
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

// CVA Guide for Forward Head
struct CVAGuideView: View {
    let size: CGSize
    
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

// Spine Guide for Back Slouch
struct SpineGuideView: View {
    let size: CGSize
    
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

// Simple Result View
struct SimpleResultView: View {
    let result: AnalysisResult
    let postureType: PostureType
    @Environment(\.dismiss) var dismiss
    
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

// Add the Camera Preview Layer
struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
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
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}


