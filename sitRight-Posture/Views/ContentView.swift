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
                            StatItem(title: "Sessions", value: "0", color: .blue)
                            StatItem(title: "Issues", value: "0", color: .orange)
                            StatItem(title: "Score", value: "--", color: .green)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                    
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
    /// The body of the `HistoryView`.
    var body: some View {
        NavigationView {
            List {
                Text("No history yet")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("History")
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