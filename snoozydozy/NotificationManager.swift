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
            
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
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
            print("Notifications not authorized")
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
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Bedtime reminder scheduled for \(String(format: "%02d:%02d", reminderHour, reminderMinute)) (1 hour before average sleep time \(String(format: "%02d:%02d", averageSleepTime.hour, averageSleepTime.minute)))")
            }
        }
    }
    
    /// Cancel the bedtime reminder notification
    func cancelBedtimeReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        print("Bedtime reminder cancelled")
    }
    
    /// Update the bedtime reminder based on current settings and sleep data
    func updateBedtimeReminder(notificationsEnabled: Bool, minutesBefore: Int = 60) {
        if notificationsEnabled && isAuthorized {
            // Calculate average sleep time from stored data
            let calculator = SleepStatisticsCalculator()
            let averageTime = calculator.averageEinschlafzeit()
            
            if let avgTime = averageTime {
                scheduleBedtimeReminder(averageSleepTime: avgTime, minutesBefore: minutesBefore)
            } else {
                print("No sleep data available to calculate average bedtime")
                cancelBedtimeReminder()
            }
        } else {
            cancelBedtimeReminder()
        }
    }
}
