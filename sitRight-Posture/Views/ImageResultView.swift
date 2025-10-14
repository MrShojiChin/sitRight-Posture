//
//  ImageResultView.swift
//  sitRight-Posture
//
//  View to display captured image with analysis results and pose overlay
//

import SwiftUI
import Vision

/// A view that displays the captured image with pose overlay and analysis results
struct ImageResultView: View {
    let result: AnalysisResultWithImage
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Captured Image with Overlay
                    ZStack {
                        Image(uiImage: result.capturedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .overlay(
                                PoseOverlayView(
                                    image: result.capturedImage,
                                    pose: result.poseObservation,
                                    postureType: result.postureType,
                                    angle: result.angle
                                )
                            )
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal)
                    
                    // Analysis Results Card
                    VStack(spacing: 20) {
                        // Status Header
                        HStack {
                            Image(systemName: result.isNormal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(result.statusColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.status)
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text(result.postureType.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Severity Badge
                            Text(result.severity)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(result.statusColor.opacity(0.2))
                                )
                                .foregroundColor(result.statusColor)
                        }
                        
                        Divider()
                        
                        // Metrics Grid
                        VStack(spacing: 16) {
                            MetricItemView(
                                icon: "ruler",
                                label: "Measured Angle",
                                value: String(format: "%.1f°", result.angle),
                                valueColor: result.statusColor
                            )
                            
                            MetricItemView(
                                icon: "checkmark.shield",
                                label: "Normal Range",
                                value: result.postureType.normalRange,
                                valueColor: .green
                            )
                            
                            MetricItemView(
                                icon: "gauge",
                                label: "Confidence",
                                value: String(format: "%.0f%%", result.confidence * 100),
                                valueColor: .blue
                            )
                            
                            MetricItemView(
                                icon: "clock",
                                label: "Captured",
                                value: DateFormatter.localizedString(from: result.timestamp, dateStyle: .none, timeStyle: .medium),
                                valueColor: .secondary
                            )
                        }
                        
                        Divider()
                        
                        // Recommendation Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Recommendation", systemImage: "lightbulb.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                            
                            Text(result.recommendation)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Analysis Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareImage()])
        }
    }
    
    /// Generates an image with overlay for sharing
    private func generateShareImage() -> UIImage {
        // Create a renderer to combine the image and overlay
        let renderer = UIGraphicsImageRenderer(size: result.capturedImage.size)
        
        return renderer.image { context in
            // Draw the original image
            result.capturedImage.draw(at: .zero)
            
            // Add overlay drawings if needed
            // This is simplified - you might want to add pose skeleton overlay here
        }
    }
}

/// A view component for displaying a metric item
struct MetricItemView: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

/// A view that draws pose overlay on the captured image
struct PoseOverlayView: View {
    let image: UIImage
    let pose: VNHumanBodyPoseObservation?
    let postureType: PostureType
    let angle: Double
    
    var body: some View {
        GeometryReader { geometry in
            if let pose = pose {
                Canvas { context, size in
                    // Draw key points and connections based on posture type
                    drawPoseOverlay(context: context, size: size, pose: pose)
                }
            }
        }
    }
    
    private func drawPoseOverlay(context: GraphicsContext, size: CGSize, pose: VNHumanBodyPoseObservation) {
        // Define colors
        let pointColor = Color.blue
        let lineColor = Color.cyan
        let angleColor = Color.orange
        
        // Helper function to convert Vision coordinates to view coordinates
        // Vision coordinates: origin at bottom-left, y increases upward
        // View coordinates: origin at top-left, y increases downward
        // For front camera with corrected orientation
        func convertPoint(_ visionPoint: CGPoint) -> CGPoint {
            // Since the image has been corrected for orientation,
            // we need to map the coordinates accordingly
            return CGPoint(
                x: (1.0 - visionPoint.x) * size.width,  // Mirror horizontally for front camera
                y: (1.0 - visionPoint.y) * size.height  // Invert Y coordinate
            )
        }
        
        // Draw based on posture type
        switch postureType {
        case .forwardHead:
            drawForwardHeadOverlay(context: context, size: size, pose: pose, convertPoint: convertPoint)
        case .roundedShoulder:
            drawRoundedShoulderOverlay(context: context, size: size, pose: pose, convertPoint: convertPoint)
        case .backSlouch:
            drawBackSlouchOverlay(context: context, size: size, pose: pose, convertPoint: convertPoint)
        }
        
        // Draw angle measurement
        drawAngleIndicator(context: context, size: size)
    }
    
    private func drawForwardHeadOverlay(context: GraphicsContext, size: CGSize, pose: VNHumanBodyPoseObservation, convertPoint: (CGPoint) -> CGPoint) {
        // Get key points for forward head analysis
        guard let rightEar = try? pose.recognizedPoint(.rightEar),
              let leftEar = try? pose.recognizedPoint(.leftEar),
              let rightShoulder = try? pose.recognizedPoint(.rightShoulder),
              let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
              rightEar.confidence > 0.5,
              leftEar.confidence > 0.5 else { return }
        
        // Calculate midpoints
        let earMidpoint = CGPoint(
            x: (rightEar.location.x + leftEar.location.x) / 2,
            y: (rightEar.location.y + leftEar.location.y) / 2
        )
        let shoulderMidpoint = CGPoint(
            x: (rightShoulder.location.x + leftShoulder.location.x) / 2,
            y: (rightShoulder.location.y + leftShoulder.location.y) / 2
        )
        
        let earPoint = convertPoint(earMidpoint)
        let shoulderPoint = convertPoint(shoulderMidpoint)
        
        // Draw vertical reference line through shoulder
        var verticalPath = Path()
        verticalPath.move(to: CGPoint(x: shoulderPoint.x, y: 0))
        verticalPath.addLine(to: CGPoint(x: shoulderPoint.x, y: size.height))
        context.stroke(verticalPath, with: .color(.gray.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        
        // Draw line from ear to shoulder
        var path = Path()
        path.move(to: earPoint)
        path.addLine(to: shoulderPoint)
        context.stroke(path, with: .color(.cyan), lineWidth: 3)
        
        // Draw points
        context.fill(Circle().path(in: CGRect(center: earPoint, radius: 6)), with: .color(.blue))
        context.fill(Circle().path(in: CGRect(center: shoulderPoint, radius: 6)), with: .color(.green))
    }
    
    private func drawRoundedShoulderOverlay(context: GraphicsContext, size: CGSize, pose: VNHumanBodyPoseObservation, convertPoint: (CGPoint) -> CGPoint) {
        // Similar implementation for rounded shoulders
        guard let rightShoulder = try? pose.recognizedPoint(.rightShoulder),
              let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
              let rightHip = try? pose.recognizedPoint(.rightHip),
              let leftHip = try? pose.recognizedPoint(.leftHip) else { return }
        
        let shoulderMidpoint = CGPoint(
            x: (rightShoulder.location.x + leftShoulder.location.x) / 2,
            y: (rightShoulder.location.y + leftShoulder.location.y) / 2
        )
        let hipMidpoint = CGPoint(
            x: (rightHip.location.x + leftHip.location.x) / 2,
            y: (rightHip.location.y + leftHip.location.y) / 2
        )
        
        let shoulderPoint = convertPoint(shoulderMidpoint)
        let hipPoint = convertPoint(hipMidpoint)
        
        // Draw vertical line through hip
        var verticalPath = Path()
        verticalPath.move(to: CGPoint(x: hipPoint.x, y: 0))
        verticalPath.addLine(to: CGPoint(x: hipPoint.x, y: size.height))
        context.stroke(verticalPath, with: .color(.gray.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        
        // Draw points and connection
        context.fill(Circle().path(in: CGRect(center: shoulderPoint, radius: 6)), with: .color(.orange))
        context.fill(Circle().path(in: CGRect(center: hipPoint, radius: 6)), with: .color(.green))
    }
    
    private func drawBackSlouchOverlay(context: GraphicsContext, size: CGSize, pose: VNHumanBodyPoseObservation, convertPoint: (CGPoint) -> CGPoint) {
        // Implementation for back slouch visualization
        guard let neck = try? pose.recognizedPoint(.neck),
              let rightShoulder = try? pose.recognizedPoint(.rightShoulder),
              let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
              let rightHip = try? pose.recognizedPoint(.rightHip),
              let leftHip = try? pose.recognizedPoint(.leftHip) else { return }
        
        let shoulderMidpoint = CGPoint(
            x: (rightShoulder.location.x + leftShoulder.location.x) / 2,
            y: (rightShoulder.location.y + leftShoulder.location.y) / 2
        )
        let hipMidpoint = CGPoint(
            x: (rightHip.location.x + leftHip.location.x) / 2,
            y: (rightHip.location.y + leftHip.location.y) / 2
        )
        
        let neckPoint = convertPoint(neck.location)
        let shoulderPoint = convertPoint(shoulderMidpoint)
        let hipPoint = convertPoint(hipMidpoint)
        
        // Draw spine curve
        var spinePath = Path()
        spinePath.move(to: neckPoint)
        spinePath.addQuadCurve(to: hipPoint, control: shoulderPoint)
        context.stroke(spinePath, with: .color(.pink), lineWidth: 3)
        
        // Draw points
        context.fill(Circle().path(in: CGRect(center: neckPoint, radius: 6)), with: .color(.blue))
        context.fill(Circle().path(in: CGRect(center: shoulderPoint, radius: 6)), with: .color(.orange))
        context.fill(Circle().path(in: CGRect(center: hipPoint, radius: 6)), with: .color(.green))
    }
    
    private func drawAngleIndicator(context: GraphicsContext, size: CGSize) {
        // Draw angle value in top corner
        let angleText = String(format: "%.1f°", angle)
        let textRect = CGRect(x: size.width - 80, y: 20, width: 70, height: 30)
        
        // Background for better visibility
        context.fill(RoundedRectangle(cornerRadius: 8).path(in: textRect), with: .color(.black.opacity(0.6)))
        
        // Angle text
        context.draw(Text(angleText)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white),
            at: CGPoint(x: textRect.midX, y: textRect.midY)
        )
    }
}

// Helper extension for CGRect
extension CGRect {
    init(center: CGPoint, radius: CGFloat) {
        self.init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

// ShareSheet for sharing the image
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
