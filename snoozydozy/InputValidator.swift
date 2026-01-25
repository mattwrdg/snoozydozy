//
//  InputValidator.swift
//  snoozydozy
//
//  Created by Matthias on 23.01.26.
//

import Foundation

// MARK: - Input Validator
struct InputValidator {
    /// Validates and sanitizes baby name
    static func validateName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitized = String(trimmed.prefix(ValidationConstants.maxNameLength))
        return sanitized
    }
    
    /// Validates height input
    static func validateHeight(_ heightString: String) -> String? {
        guard let height = Int(heightString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        
        if height >= ValidationConstants.minHeight && height <= ValidationConstants.maxHeight {
            return String(height)
        }
        
        return nil
    }
    
    /// Validates weight input
    static func validateWeight(_ weightString: String) -> String? {
        guard let weight = Int(weightString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        
        if weight >= ValidationConstants.minWeight && weight <= ValidationConstants.maxWeight {
            return String(weight)
        }
        
        return nil
    }
    
    /// Validates date is not in the future
    static func validateBirthday(_ date: Date) -> Bool {
        return date <= Date()
    }
}
