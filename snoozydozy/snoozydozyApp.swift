//
//  snoozydozyApp.swift
//  snoozydozy
//
//  Created by Matthias on 20.01.26.
//

import SwiftUI

@main
struct SnoozyDozzyApp: App {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderMinutesBefore") private var reminderMinutesBefore = 60
    
    init() {
        // Check notification authorization status on launch
        NotificationManager.shared.checkAuthorizationStatus()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Update bedtime reminder when app launches (if notifications are enabled)
                    if notificationsEnabled {
                        NotificationManager.shared.updateBedtimeReminder(notificationsEnabled: true, minutesBefore: reminderMinutesBefore)
                    }
                }
        }
    }
}
