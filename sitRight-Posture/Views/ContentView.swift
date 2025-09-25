//
//  ContentView.swift
//  sitRight-Posture
//
//  Created by Ryu on 7/9/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
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

// Keep your existing placeholder views
struct DashboardView: View {
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

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
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

struct HistoryView: View {
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

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("analysisFrequency") private var analysisFrequency = 30
    
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
