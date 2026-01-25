//
//  NotificationManager.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationManager: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private let notificationIdentifier = "bedtimeReminder"
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
            
            #if DEBUG
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            #endif
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule a bedtime reminder notification
    /// - Parameters:
    ///   - averageSleepTime: The average bedtime as (hour, minute) tuple
    ///   - minutesBefore: How many minutes before the bedtime to send the notification (default: 60)
    func scheduleBedtimeReminder(averageSleepTime: (hour: Int, minute: Int), minutesBefore: Int = 60) {
        // First, cancel any existing bedtime reminder
        cancelBedtimeReminder()
        
        guard isAuthorized else {
            #if DEBUG
            print("Notifications not authorized")
            #endif
            return
        }
        
        // Calculate the reminder time (1 hour before average sleep time)
        var reminderHour = averageSleepTime.hour
        var reminderMinute = averageSleepTime.minute - minutesBefore
        
        // Handle negative minutes
        while reminderMinute < 0 {
            reminderMinute += 60
            reminderHour -= 1
        }
        
        // Handle negative hours (wrap around to previous day)
        if reminderHour < 0 {
            reminderHour += 24
        }
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Schlafenszeit naht"
        
        // Format the time message based on minutes before
        let timeMessage: String
        if minutesBefore == 60 {
            timeMessage = "In einer Stunde ist die durchschnittliche Einschlafzeit. Zeit, langsam zur Ruhe zu kommen."
        } else if minutesBefore < 60 {
            timeMessage = "In \(minutesBefore) Minuten ist die durchschnittliche Einschlafzeit. Zeit, langsam zur Ruhe zu kommen."
        } else {
            let hours = minutesBefore / 60
            let remainingMinutes = minutesBefore % 60
            if remainingMinutes == 0 {
                timeMessage = "In \(hours) Stunde\(hours > 1 ? "n" : "") ist die durchschnittliche Einschlafzeit. Zeit, langsam zur Ruhe zu kommen."
            } else {
                timeMessage = "In \(hours) Stunde\(hours > 1 ? "n" : "") und \(remainingMinutes) Minuten ist die durchschnittliche Einschlafzeit. Zeit, langsam zur Ruhe zu kommen."
            }
        }
        content.body = timeMessage
        content.sound = .default
        
        // Create a daily trigger at the calculated time
        // For daily repeating notifications, only specify hour and minute
        // iOS will automatically repeat this every day
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        // Note: We don't set day, month, or year - this allows it to repeat daily
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Bedtime reminder scheduled for daily at \(String(format: "%02d:%02d", reminderHour, reminderMinute)) (repeats: true)")
                // Verify the notification was scheduled correctly
                Task { @MainActor in
                    self.verifyScheduledNotification()
                }
            }
            #endif
        }
    }
    
    /// Verify that the notification was scheduled correctly (for debugging)
    private func verifyScheduledNotification() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let bedtimeReminder = requests.first { $0.identifier == self.notificationIdentifier }
            if let reminder = bedtimeReminder,
               let trigger = reminder.trigger as? UNCalendarNotificationTrigger {
                #if DEBUG
                print("📋 Verification - Notification found:")
                print("   Identifier: \(reminder.identifier)")
                print("   Title: \(reminder.content.title)")
                print("   Body: \(reminder.content.body)")
                print("   Repeats: \(trigger.repeats)")
                let dateComponents = trigger.dateComponents
                print("   Time: \(String(format: "%02d:%02d", dateComponents.hour ?? 0, dateComponents.minute ?? 0))")
                #endif
            } else {
                #if DEBUG
                print("⚠️ Warning: Bedtime reminder notification not found in pending notifications!")
                #endif
            }
        }
    }
    
    /// Cancel the bedtime reminder notification
    func cancelBedtimeReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    /// Update the bedtime reminder based on current settings and sleep data
    /// Only reschedules if the time has changed to avoid interfering with the daily repeat
    func updateBedtimeReminder(notificationsEnabled: Bool, minutesBefore: Int = 60) {
        if notificationsEnabled && isAuthorized {
            // Calculate average sleep time from stored data
            let calculator = SleepStatisticsCalculator()
            let averageTime = calculator.averageEinschlafzeit()
            
            if let avgTime = averageTime {
                // Calculate the reminder time
                var reminderHour = avgTime.hour
                var reminderMinute = avgTime.minute - minutesBefore
                
                while reminderMinute < 0 {
                    reminderMinute += 60
                    reminderHour -= 1
                }
                
                if reminderHour < 0 {
                    reminderHour += 24
                }
                
                // Check if we need to reschedule by comparing with existing notification
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let existingReminder = requests.first { $0.identifier == self.notificationIdentifier }
                    
                    var needsReschedule = true
                    if let existing = existingReminder,
                       let trigger = existing.trigger as? UNCalendarNotificationTrigger {
                        let existingComponents = trigger.dateComponents
                        if existingComponents.hour == reminderHour &&
                           existingComponents.minute == reminderMinute &&
                           trigger.repeats == true {
                            // Same time and already repeating - no need to reschedule
                            needsReschedule = false
                            #if DEBUG
                            print("ℹ️ Bedtime reminder already scheduled correctly, skipping reschedule")
                            #endif
                        }
                    }
                    
                    if needsReschedule {
                        DispatchQueue.main.async { [weak self] in
                            self?.scheduleBedtimeReminder(averageSleepTime: avgTime, minutesBefore: minutesBefore)
                        }
                    }
                }
            } else {
                #if DEBUG
                print("No sleep data available to calculate average bedtime")
                #endif
                cancelBedtimeReminder()
            }
        } else {
            cancelBedtimeReminder()
        }
    }
}
