//
//  SettingsView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderMinutesBefore") private var reminderMinutesBefore = 60
    @State private var isTimePickerExpanded = false
    @StateObject private var calculator = SleepStatisticsCalculator()
    @State private var showShareSheet = false
    @State private var exportFileURL: URL?
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var showFileImporter = false
    @State private var showImportConfirmation = false
    @State private var importFileURL: URL?
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var showImportSuccess = false
    
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
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.18)
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
                                                    .background(Color(red: 0.55, green: 0.5, blue: 0.75))
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
                        
                        // App Settings Section
                        SettingsSection(title: "App") {
                            SettingsRow(icon: "paintbrush.fill", iconColor: .purple, title: "Design") {
                                HStack(spacing: 6) {
                                    Text("Dunkel")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                        
                        // Data Export/Import Section
                        SettingsSection(title: "Daten") {
                            Button(action: {
                                exportData()
                            }) {
                                SettingsRow(icon: "square.and.arrow.up.fill", iconColor: .green, title: "Daten exportieren") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            Button(action: {
                                showFileImporter = true
                            }) {
                                SettingsRow(icon: "square.and.arrow.down.fill", iconColor: .blue, title: "Daten importieren") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
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
                            
                            SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "Datenschutz") {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            SettingsRow(icon: "heart.fill", iconColor: .red, title: "App bewerten") {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
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
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = exportFileURL {
                ShareSheet(activityItems: [fileURL])
            }
        }
        .alert("Export Fehler", isPresented: $showExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importFileURL = url
                    showImportConfirmation = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showImportError = true
            }
        }
        .alert("Daten importieren", isPresented: $showImportConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Importieren") {
                importData()
            }
        } message: {
            Text("Möchten Sie wirklich alle aktuellen Daten durch die importierten Daten ersetzen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Import Fehler", isPresented: $showImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
        .alert("Import erfolgreich", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Die Daten wurden erfolgreich importiert.")
        }
    }
    
    // Export data function
    private func exportData() {
        do {
            let fileURL = try DataExportManager.shared.exportToJSON()
            exportFileURL = fileURL
            showShareSheet = true
        } catch {
            exportErrorMessage = "Fehler beim Exportieren der Daten: \(error.localizedDescription)"
            showExportError = true
        }
    }
    
    // Import data function
    private func importData() {
        guard let fileURL = importFileURL else {
            importErrorMessage = "Keine Datei ausgewählt"
            showImportError = true
            return
        }
        
        // Need to access security-scoped resource
        guard fileURL.startAccessingSecurityScopedResource() else {
            importErrorMessage = "Kein Zugriff auf die Datei"
            showImportError = true
            return
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            try DataExportManager.shared.importFromJSON(url: fileURL)
            showImportSuccess = true
            // Reload calculator to reflect imported data
            calculator.loadEntries()
        } catch {
            importErrorMessage = "Fehler beim Importieren der Daten: \(error.localizedDescription)"
            showImportError = true
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
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.28))
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
                .tint(Color(red: 0.55, green: 0.5, blue: 0.75))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    SettingsView()
}
