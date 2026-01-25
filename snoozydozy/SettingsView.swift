//
//  SettingsView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(StorageKeys.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(StorageKeys.reminderMinutesBefore) private var reminderMinutesBefore = 60
    @State private var isTimePickerExpanded = false
    @StateObject private var calculator = SleepStatisticsCalculator()
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    // Convert reminderMinutesBefore to Date for picker
    private var reminderTimeForPicker: Date {
        let calendar = Calendar.current
        let hours = reminderMinutesBefore / 60
        let minutes = reminderMinutesBefore % 60
        var components = DateComponents()
        components.hour = hours
        components.minute = minutes
        return calendar.date(from: components) ?? Date()
    }
    
    // Calculate the notification time based on user preference
    private var notificationTimeDescription: String {
        guard let avgTime = calculator.averageEinschlafzeit() else {
            return "Keine Schlafdaten vorhanden"
        }
        
        // Calculate reminder time based on user preference
        var reminderHour = avgTime.hour
        var reminderMinute = avgTime.minute - reminderMinutesBefore
        
        while reminderMinute < 0 {
            reminderMinute += 60
            reminderHour -= 1
        }
        
        if reminderHour < 0 {
            reminderHour += 24
        }
        
        let avgTimeString = String(format: "%02d:%02d", avgTime.hour, avgTime.minute)
        let reminderTimeString = String(format: "%02d:%02d", reminderHour, reminderMinute)
        
        // Format the minutes before text
        let minutesText: String
        if reminderMinutesBefore == 60 {
            minutesText = "1 Stunde"
        } else if reminderMinutesBefore < 60 {
            minutesText = "\(reminderMinutesBefore) Minuten"
        } else {
            let hours = reminderMinutesBefore / 60
            let remainingMinutes = reminderMinutesBefore % 60
            if remainingMinutes == 0 {
                minutesText = "\(hours) Stunde\(hours > 1 ? "n" : "")"
            } else {
                minutesText = "\(hours) Stunde\(hours > 1 ? "n" : "") und \(remainingMinutes) Minuten"
            }
        }
        
        return "Täglich um \(reminderTimeString) Uhr (\(minutesText) vor Ø Einschlafzeit: \(avgTimeString))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.backgroundDark
                    .ignoresSafeArea()
                
                // Stars
                StarFieldAnimated()
                    .allowsHitTesting(false)
                
                ScrollView {
                VStack(spacing: 0) {
                    // Header
                    Text("Einstellungen")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    
                    VStack(spacing: 20) {
                        // Notifications Section
                        SettingsSection(title: "Benachrichtigungen") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: .orange,
                                title: "Benachrichtigungen",
                                isOn: Binding(
                                    get: { notificationsEnabled },
                                    set: { newValue in
                                        if newValue {
                                            // Request permission when enabling
                                            notificationManager.requestAuthorization { granted in
                                                notificationsEnabled = granted
                                                if granted {
                                                    notificationManager.updateBedtimeReminder(notificationsEnabled: true, minutesBefore: reminderMinutesBefore)
                                                }
                                            }
                                        } else {
                                            notificationsEnabled = false
                                            notificationManager.cancelBedtimeReminder()
                                        }
                                    }
                                )
                            )
                            
                            if notificationsEnabled {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.indigo.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "moon.zzz.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.indigo)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Schlafenszeit-Erinnerung")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(notificationTimeDescription)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Reminder time adjustment
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("Erinnerung vor Einschlafzeit")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Spacer()
                                    }
                                    
                                    if isTimePickerExpanded {
                                        VStack(spacing: 12) {
                                            DatePicker("", selection: Binding(
                                                get: {
                                                    reminderTimeForPicker
                                                },
                                                set: { newDate in
                                                    let calendar = Calendar.current
                                                    let hours = calendar.component(.hour, from: newDate)
                                                    let minutes = calendar.component(.minute, from: newDate)
                                                    reminderMinutesBefore = hours * 60 + minutes
                                                    
                                                    if notificationsEnabled {
                                                        notificationManager.updateBedtimeReminder(notificationsEnabled: true, minutesBefore: reminderMinutesBefore)
                                                    }
                                                }
                                            ), displayedComponents: [.hourAndMinute])
                                            .datePickerStyle(.wheel)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                            .frame(maxWidth: .infinity)
                                            .background(Color(red: 0.25, green: 0.2, blue: 0.35))
                                            .cornerRadius(12)
                                            
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isTimePickerExpanded = false
                                                }
                                            }) {
                                                Text("Fertig")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(AppColors.accentSecondary)
                                                    .cornerRadius(12)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .transition(.opacity.combined(with: .scale))
                                    } else {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isTimePickerExpanded = true
                                            }
                                        }) {
                                            HStack {
                                                Text(formatReminderTime(reminderMinutesBefore))
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .rotationEffect(.degrees(isTimePickerExpanded ? 180 : 0))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color(red: 0.25, green: 0.2, blue: 0.35))
                                            .cornerRadius(12)
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .animation(.easeInOut(duration: 0.2), value: isTimePickerExpanded)
                            }
                        }
                        
                        // About Section
                        SettingsSection(title: "Über") {
                            SettingsRow(icon: "info.circle.fill", iconColor: .blue, title: "Version") {
                                Text("1.0.0")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: TermsAndConditionsView()) {
                                SettingsRow(icon: "doc.text.fill", iconColor: .blue, title: "Geschäftsbedingungen") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: PrivacyPolicyView()) {
                                SettingsRow(icon: "lock.shield.fill", iconColor: .green, title: "Datenschutzerklärung") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: DisclaimerView()) {
                                SettingsRow(icon: "exclamationmark.triangle.fill", iconColor: .orange, title: "Haftungsausschluss") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                        
                        // Version info
                        Text("Made with love for happy sleeping babies")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for tab bar
                }
                }
                .scrollIndicators(.hidden)
            }
            .onAppear {
                calculator.loadEntries()
            }
        }
    }
    
    // Helper function to format reminder time
    private func formatReminderTime(_ minutes: Int) -> String {
        if minutes == 60 {
            return "1 Stunde"
        } else if minutes < 60 {
            return "\(minutes) Min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) Std"
            } else {
                return "\(hours) Std \(remainingMinutes) Min"
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.backgroundCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let accessory: () -> Accessory
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            accessory()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accentSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
}
