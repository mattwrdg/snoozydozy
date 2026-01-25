//
//  DataExportManager.swift
//  snoozydozy
//
//  Created by Matthias on 25.01.26.
//

import Foundation
import SwiftUI

// MARK: - Export Data Model
struct ExportData: Codable {
    let metadata: ExportMetadata
    let babyProfile: BabyProfile
    let appSettings: AppSettings
    let sleepEntries: [SleepEntry]
}

struct ExportMetadata: Codable {
    let exportDate: Date
    let appVersion: String
}

struct AppSettings: Codable {
    let notificationsEnabled: Bool
    let reminderMinutesBefore: Int
}

// MARK: - Data Export Manager
@MainActor
class DataExportManager {
    static let shared = DataExportManager()
    
    private let appVersion = "1.0.0"
    
    private init() {}
    
    /// Collects all app data and creates export data structure
    func collectExportData() -> ExportData {
        // Get baby profile
        let babyProfile = BabyProfileManager.shared.profile
        
        // Get sleep entries (including ongoing ones)
        let sleepEntries = SleepStorageManager.shared.load()
        
        // Get app settings from UserDefaults
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        let reminderMinutesBefore = UserDefaults.standard.integer(forKey: "reminderMinutesBefore")
        // Default to 60 if not set
        let reminderMinutes = reminderMinutesBefore == 0 ? 60 : reminderMinutesBefore
        
        let appSettings = AppSettings(
            notificationsEnabled: notificationsEnabled,
            reminderMinutesBefore: reminderMinutes
        )
        
        let metadata = ExportMetadata(
            exportDate: Date(),
            appVersion: appVersion
        )
        
        return ExportData(
            metadata: metadata,
            babyProfile: babyProfile,
            appSettings: appSettings,
            sleepEntries: sleepEntries
        )
    }
    
    /// Exports data to JSON and returns the file URL
    func exportToJSON() throws -> URL {
        let exportData = collectExportData()
        
        // Encode to JSON with pretty printing
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "snoozydozy_export_\(timestamp).json"
        
        // Save to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Imports data from JSON file and restores all app data
    func importFromJSON(url: URL) throws {
        // Read JSON data from file
        let jsonData = try Data(contentsOf: url)
        
        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(ExportData.self, from: jsonData)
        
        // Restore baby profile
        BabyProfileManager.shared.update(exportData.babyProfile)
        
        // Restore app settings
        UserDefaults.standard.set(exportData.appSettings.notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(exportData.appSettings.reminderMinutesBefore, forKey: "reminderMinutesBefore")
        
        // Restore sleep entries (including ongoing ones with endTime: null)
        SleepStorageManager.shared.save(exportData.sleepEntries)
        
        // Update notifications if they were enabled
        if exportData.appSettings.notificationsEnabled {
            NotificationManager.shared.updateBedtimeReminder(
                notificationsEnabled: true,
                minutesBefore: exportData.appSettings.reminderMinutesBefore
            )
        } else {
            NotificationManager.shared.cancelBedtimeReminder()
        }
    }
}
