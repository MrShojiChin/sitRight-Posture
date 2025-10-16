//
//  HistoryManager.swift
//  sitRight-Posture
//
//  Manages saving and loading of posture analysis history
//

import Foundation
import SwiftUI
import Vision

/// Manager class for handling analysis history persistence
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var analysisHistory: [AnalysisResultWithImage] = []
    
    private let documentsDirectory: URL
    private let historyFileName = "analysisHistory.json"
    private let imagesDirectoryName = "analysisImages"
    
    private init() {
        // Get documents directory
        documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first!
        
        // Create images directory if it doesn't exist
        let imagesDirectory = documentsDirectory.appendingPathComponent(imagesDirectoryName)
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(at: imagesDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
        
        // Load existing history
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// Saves a new analysis result to history
    func saveAnalysisResult(_ result: AnalysisResultWithImage) {
        // Save image
        let imageFileName = "\(result.id.uuidString).jpg"
        let imageURL = documentsDirectory
            .appendingPathComponent(imagesDirectoryName)
            .appendingPathComponent(imageFileName)
        
        if let imageData = result.capturedImage.jpegData(compressionQuality: 0.8) {
            try? imageData.write(to: imageURL)
        }
        
        // Create persistent record
        let record = AnalysisRecord(
            id: result.id,
            postureType: result.postureType.rawValue,
            angle: result.angle,
            isNormal: result.isNormal,
            confidence: result.confidence,
            timestamp: result.timestamp,
            recommendation: result.recommendation,
            severity: result.severity,
            imageFileName: imageFileName
        )
        
        // Add to history (newest first)
        var records = loadRecords()
        records.insert(record, at: 0)
        
        // Limit history to last 100 items
        if records.count > 100 {
            // Remove old images
            for oldRecord in records.suffix(records.count - 100) {
                deleteImage(fileName: oldRecord.imageFileName)
            }
            records = Array(records.prefix(100))
        }
        
        // Save records
        saveRecords(records)
        
        // Update published property
        loadHistory()
    }
    
    /// Deletes an analysis result from history
    func deleteAnalysisResult(at offsets: IndexSet) {
        var records = loadRecords()
        
        for index in offsets {
            if index < records.count {
                // Delete associated image
                deleteImage(fileName: records[index].imageFileName)
                records.remove(at: index)
            }
        }
        
        saveRecords(records)
        loadHistory()
    }
    
    /// Deletes a specific analysis result by ID
    func deleteAnalysisResult(id: UUID) {
        var records = loadRecords()
        
        if let index = records.firstIndex(where: { $0.id == id }) {
            deleteImage(fileName: records[index].imageFileName)
            records.remove(at: index)
            saveRecords(records)
            loadHistory()
        }
    }
    
    /// Clears all history
    func clearAllHistory() {
        // Delete all images
        let imagesDirectory = documentsDirectory.appendingPathComponent(imagesDirectoryName)
        if let imageURLs = try? FileManager.default.contentsOfDirectory(at: imagesDirectory,
                                                                       includingPropertiesForKeys: nil) {
            for imageURL in imageURLs {
                try? FileManager.default.removeItem(at: imageURL)
            }
        }
        
        // Clear records
        saveRecords([])
        loadHistory()
    }
    
    /// Gets grouped history by date
    func getGroupedHistory() -> [(date: Date, results: [AnalysisResultWithImage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: analysisHistory) { result in
            calendar.startOfDay(for: result.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, results: $0.value) }
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        let records = loadRecords()
        
        analysisHistory = records.compactMap { record in
            // Load image
            let imageURL = documentsDirectory
                .appendingPathComponent(imagesDirectoryName)
                .appendingPathComponent(record.imageFileName)
            
            guard let imageData = try? Data(contentsOf: imageURL),
                  let image = UIImage(data: imageData),
                  let postureType = PostureType(rawValue: record.postureType) else {
                return nil
            }
            
            return AnalysisResultWithImage(
                capturedImage: image,
                postureType: postureType,
                angle: record.angle,
                isNormal: record.isNormal,
                confidence: record.confidence,
                poseObservation: nil, // We don't persist the pose observation
                recommendation: record.recommendation
            )
        }
    }
    
    private func loadRecords() -> [AnalysisRecord] {
        let url = documentsDirectory.appendingPathComponent(historyFileName)
        
        guard let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([AnalysisRecord].self, from: data) else {
            return []
        }
        
        return records
    }
    
    private func saveRecords(_ records: [AnalysisRecord]) {
        let url = documentsDirectory.appendingPathComponent(historyFileName)
        
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: url)
        }
    }
    
    private func deleteImage(fileName: String) {
        let imageURL = documentsDirectory
            .appendingPathComponent(imagesDirectoryName)
            .appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: imageURL)
    }
}

// MARK: - Analysis Record Model
private struct AnalysisRecord: Codable {
    let id: UUID
    let postureType: String
    let angle: Double
    let isNormal: Bool
    let confidence: Double
    let timestamp: Date
    let recommendation: String
    let severity: String
    let imageFileName: String
}
