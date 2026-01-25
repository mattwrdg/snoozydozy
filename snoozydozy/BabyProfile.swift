//
//  BabyProfile.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import Foundation
import Combine

// MARK: - Baby Profile Model
struct BabyProfile: Codable {
    var name: String
    var birthday: Date
    var gender: String // "Junge" or "Mädchen"
    var breastfeeding: String // "Ja" or "Nein"
    var height: String // in cm
    var weight: String // in g
    
    init(
        name: String = "Baby Name",
        birthday: Date = Date(timeIntervalSince1970: 1735689600), // January 1, 2026
        gender: String = "Junge",
        breastfeeding: String = "Ja",
        height: String = "52",
        weight: String = "3750"
    ) {
        self.name = name
        self.birthday = birthday
        self.gender = gender
        self.breastfeeding = breastfeeding
        self.height = height
        self.weight = weight
    }
}

// MARK: - Baby Profile Storage Manager
class BabyProfileManager: ObservableObject {
    static let shared = BabyProfileManager()
    
    @Published var profile: BabyProfile {
        didSet {
            save()
        }
    }
    
    private init() {
        self.profile = BabyProfileManager.load()
    }
    
    private static func load() -> BabyProfile {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.babyProfile),
              let profile = try? JSONDecoder().decode(BabyProfile.self, from: data) else {
            return BabyProfile()
        }
        return profile
    }
    
    private func save() {
        do {
            let encoded = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(encoded, forKey: StorageKeys.babyProfile)
        } catch {
            // Log error in production, fail silently for user experience
            #if DEBUG
            print("Error saving baby profile: \(error.localizedDescription)")
            #endif
        }
    }
    
    func update(_ newProfile: BabyProfile) {
        // Validate and sanitize input before updating
        var validatedProfile = newProfile
        validatedProfile.name = InputValidator.validateName(newProfile.name)
        
        if let validatedHeight = InputValidator.validateHeight(newProfile.height) {
            validatedProfile.height = validatedHeight
        }
        
        if let validatedWeight = InputValidator.validateWeight(newProfile.weight) {
            validatedProfile.weight = validatedWeight
        }
        
        if !InputValidator.validateBirthday(newProfile.birthday) {
            // If birthday is in future, use current date
            validatedProfile.birthday = Date()
        }
        
        profile = validatedProfile
    }
}
