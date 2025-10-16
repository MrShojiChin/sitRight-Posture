//
//  ContentView.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//

import SwiftUI

/// The main view of the app, which sets up the tab bar interface.
struct ContentView: View {
    /// The currently selected tab index.
    @State private var selectedTab = 0
    
    /// The body of the `ContentView`, which contains the `TabView`.
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            // Changed from CameraView to PostureAnalysisView
            PostureAnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "figure.stand")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

/// A view that displays a dashboard with a summary of posture analysis and quick tips.
struct DashboardView: View {
    @StateObject private var historyManager = HistoryManager.shared
    
    /// The body of the `DashboardView`.
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Today's Summary")
                            .font(.headline)
                        
                        HStack(spacing: 30) {
                            StatItem(
                                title: "Sessions",
                                value: "\(todaySessionCount)",
                                color: .blue
                            )
                            StatItem(
                                title: "Issues",
                                value: "\(todayIssueCount)",
                                color: .orange
                            )
                            StatItem(
                                title: "Score",
                                value: todayScore,
                                color: scoreColor
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                    
                    // Recent Analysis (if any)
                    if let latestResult = historyManager.analysisHistory.first {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Latest Analysis")
                                .font(.headline)
                            
                            LatestAnalysisCard(result: latestResult)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                    
                    // Quick Tips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Tips")
                            .font(.headline)
                        
                        Text("• Keep your screen at eye level")
                        Text("• Take breaks every 30 minutes")
                        Text("• Maintain proper chair height")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var todaySessionCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return historyManager.analysisHistory.filter {
            calendar.isDate($0.timestamp, inSameDayAs: today)
        }.count
    }
    
    private var todayIssueCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return historyManager.analysisHistory.filter {
            calendar.isDate($0.timestamp, inSameDayAs: today) && !$0.isNormal
        }.count
    }
    
    private var todayScore: String {
        guard todaySessionCount > 0 else { return "--" }
        let normalCount = todaySessionCount - todayIssueCount
        let percentage = Int((Double(normalCount) / Double(todaySessionCount)) * 100)
        return "\(percentage)%"
    }
    
    private var scoreColor: Color {
        guard todaySessionCount > 0 else { return .gray }
        let normalCount = todaySessionCount - todayIssueCount
        let percentage = Double(normalCount) / Double(todaySessionCount)
        if percentage >= 0.8 { return .green }
        else if percentage >= 0.5 { return .orange }
        else { return .red }
    }
}

/// A card showing the latest analysis result
struct LatestAnalysisCard: View {
    let result: AnalysisResultWithImage
    @State private var showingResult = false
    
    var body: some View {
        Button(action: {
            showingResult = true
        }) {
            HStack(spacing: 12) {
                // Thumbnail
                Image(uiImage: result.capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.postureType.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(result.status)
                            .font(.system(size: 13))
                            .foregroundColor(result.statusColor)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(result.timestamp))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingResult) {
            ImageResultView(result: result)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// A view for displaying a single statistic item on the dashboard.
struct StatItem: View {
    /// The title of the statistic.
    let title: String
    /// The value of the statistic.
    let value: String
    /// The color associated with the statistic's value.
    let color: Color
    
    /// The body of the `StatItem` view.
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// A view that displays the history of posture analysis sessions.
struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @State private var selectedResult: AnalysisResultWithImage?
    @State private var showingDeleteAlert = false
    @State private var showingClearAllAlert = false
    
    /// The body of the `HistoryView`.
    var body: some View {
        NavigationView {
            Group {
                if historyManager.analysisHistory.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Analysis History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your posture analysis results\nwill appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // History list
                    ScrollView {
                        VStack(spacing: 16) {
                            // Group results by date
                            ForEach(historyManager.getGroupedHistory(), id: \.date) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Date header
                                    Text(formatDateHeader(group.date))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                    
                                    // Results for this date
                                    ForEach(group.results) { result in
                                        HistoryCardView(result: result)
                                            .onTapGesture {
                                                selectedResult = result
                                            }
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !historyManager.analysisHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showingClearAllAlert = true
                            } label: {
                                Label("Clear All History", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedResult) { result in
            ImageResultView(result: result)
        }
        .alert("Clear All History", isPresented: $showingClearAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                withAnimation {
                    historyManager.clearAllHistory()
                }
            }
        } message: {
            Text("This will permanently delete all analysis history and images. This action cannot be undone.")
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - History Card View
struct HistoryCardView: View {
    let result: AnalysisResultWithImage
    @State private var showDeleteOption = false
    @StateObject private var historyManager = HistoryManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail image
            Image(uiImage: result.capturedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // Analysis details
            VStack(alignment: .leading, spacing: 6) {
                // Posture type and time
                HStack {
                    Text(result.postureType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatTime(result.timestamp))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Status badge
                HStack(spacing: 8) {
                    // Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(result.statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(result.status)
                            .font(.system(size: 14))
                            .foregroundColor(result.statusColor)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    // Angle measurement
                    Text(String(format: "%.1f°", result.angle))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Severity
                Text(result.severity.capitalized)
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(severityColor(for: result.severity).opacity(0.15))
                    )
                    .foregroundColor(severityColor(for: result.severity))
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    historyManager.deleteAnalysisResult(id: result.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func severityColor(for severity: String) -> Color {
        switch severity.lowercased() {
        case "normal":
            return .green
        case "mild":
            return .orange
        case "moderate to severe", "severe":
            return .red
        default:
            return .gray
        }
    }
}

/// A view that allows the user to configure app settings.
struct SettingsView: View {
    /// A flag to enable or disable notifications, stored in `UserDefaults`.
    @AppStorage("enableNotifications") private var enableNotifications = true
    /// The frequency of analysis in minutes, stored in `UserDefaults`.
    @AppStorage("analysisFrequency") private var analysisFrequency = 30
    
    /// The body of the `SettingsView`.
    var body: some View {
        NavigationView {
            Form {
                Section("Posture Detection") {
                    HStack {
                        Text("Detection Sensitivity")
                        Spacer()
                        Text("Medium")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Calibration")
                        Spacer()
                        Button("Recalibrate") {
                            // Calibration action
                        }
                        .font(.caption)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $enableNotifications)
                    
                    if enableNotifications {
                        Stepper("Check every \(analysisFrequency) min", value: $analysisFrequency, in: 15...120, step: 15)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Senior Project 2025")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

/// A preview provider for the `ContentView`.
struct ContentView_Previews: PreviewProvider {
    /// A static property that provides a preview of the `ContentView`.
    static var previews: some View {
        ContentView()
    }
}
