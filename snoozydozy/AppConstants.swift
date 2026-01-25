//
//  AppConstants.swift
//  snoozydozy
//
//  Created by Matthias on 23.01.26.
//

import SwiftUI

// MARK: - App Colors
enum AppColors {
    // Background colors
    static let backgroundDark = Color(red: 0.08, green: 0.08, blue: 0.18)
    static let backgroundMedium = Color(red: 0.15, green: 0.15, blue: 0.3)
    static let backgroundCard = Color(red: 0.15, green: 0.15, blue: 0.28)
    static let backgroundCardLight = Color(red: 0.25, green: 0.2, blue: 0.35)
    static let backgroundInput = Color(red: 0.2, green: 0.2, blue: 0.35)
    
    // Accent colors
    static let accentPrimary = Color(red: 0.6, green: 0.5, blue: 0.75)
    static let accentSecondary = Color(red: 0.55, green: 0.5, blue: 0.75)
    static let accentDark = Color(red: 0.5, green: 0.4, blue: 0.65)
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.7)
    static let textQuaternary = Color.white.opacity(0.5)
    static let textQuinary = Color.white.opacity(0.4)
}

// MARK: - Date Formatters
enum AppDateFormatters {
    static let dateLong: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    static let dateShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    static let dateFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let dayLetter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEEE"
        return formatter
    }()
    
    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
}

// MARK: - Validation Constants
enum ValidationConstants {
    static let maxNameLength = 50
    static let minHeight = 30
    static let maxHeight = 120
    static let minWeight = 500
    static let maxWeight = 20000
}

// MARK: - Storage Keys
enum StorageKeys {
    static let babyProfile = "babyProfile"
    static let sleepEntries = "sleepEntries"
    static let notificationsEnabled = "notificationsEnabled"
    static let reminderMinutesBefore = "reminderMinutesBefore"
}
