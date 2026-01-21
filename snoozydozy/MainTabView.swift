//
//  MainTabView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .sleep
    
    enum Tab {
        case sleep
        case statistics
        case settings
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .sleep:
                    SleepTrackingView()
                case .statistics:
                    StatisticsView()
                case .settings:
                    SettingsView()
                }
            }
            
            // Custom Tab Bar - positioned at very bottom
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        VStack(spacing: 0) {
            // Top border line
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            // Tab bar content
            HStack(spacing: 0) {
                TabBarButton(
                    icon: "moon.zzz.fill",
                    title: "Schlaf",
                    isSelected: selectedTab == .sleep
                ) {
                    selectedTab = .sleep
                }
                
                TabBarButton(
                    icon: "chart.bar.fill",
                    title: "Statistik",
                    isSelected: selectedTab == .statistics
                ) {
                    selectedTab = .statistics
                }
                
                TabBarButton(
                    icon: "gearshape.fill",
                    title: "Einstellungen",
                    isSelected: selectedTab == .settings
                ) {
                    selectedTab = .settings
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.22).opacity(0.98))
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.7, green: 0.65, blue: 0.9) : .white.opacity(0.4))
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.7, green: 0.65, blue: 0.9) : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
    }
}


#Preview {
    MainTabView()
}
