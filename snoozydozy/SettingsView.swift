//
//  SettingsView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var hapticFeedback = true
    
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
                        // Baby Profile Section
                        SettingsSection(title: "Baby-Profil") {
                            SettingsRow(icon: "person.fill", iconColor: .pink, title: "Mobi") {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        
                        // Notifications Section
                        SettingsSection(title: "Benachrichtigungen") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: .orange,
                                title: "Benachrichtigungen",
                                isOn: $notificationsEnabled
                            )
                        }
                        
                        // App Settings Section
                        SettingsSection(title: "App") {
                            SettingsToggleRow(
                                icon: "hand.tap.fill",
                                iconColor: .cyan,
                                title: "Haptisches Feedback",
                                isOn: $hapticFeedback
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
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
                        Text("Made with love for happy babies")
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

#Preview {
    SettingsView()
}
