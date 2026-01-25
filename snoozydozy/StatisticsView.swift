//
//  StatisticsView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI
import Combine
import Charts

// MARK: - Daily Sleep Data for Chart
struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let sleepHours: Double
    let dayName: String
    let isToday: Bool
    let index: Int // Index for X-axis positioning (0, 1, 2, ...)
}

// MARK: - Time Data for Chart (for sleep/wake times)
struct DailyTimeData: Identifiable {
    let id = UUID()
    let date: Date
    let timeValue: Double // Hours as decimal (e.g., 19.5 = 19:30)
    let timeString: String // Formatted time string for display
    let dayName: String
    let isToday: Bool
    let hasData: Bool
    let index: Int // Index for X-axis positioning (0, 1, 2, ...)
}

// MARK: - Sleep Statistics Calculator
@MainActor
class SleepStatisticsCalculator: ObservableObject {
    @Published var sleepEntries: [SleepEntry] = []
    
    private let calendar = Calendar.current
    
    init() {
        loadEntries()
    }
    
    func loadEntries() {
        sleepEntries = SleepStorageManager.shared.load()
    }
    
    // Get sleep data for the specified period
    func chartData(for period: StatisticsView.StatsPeriod) -> [DailySleepData] {
        let today = calendar.startOfDay(for: Date())
        var data: [DailySleepData] = []
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "de_DE")
        
        let days: Int
        switch period {
        case .week:
            days = 7
            dayFormatter.dateFormat = "EEE" // Short day name (Mo, Di, Mi, etc.)
        case .month:
            days = 30
            dayFormatter.dateFormat = "d" // Day number (1, 2, 3, etc.)
        case .all:
            days = 7 // Default to week view for "all"
            dayFormatter.dateFormat = "EEE"
        }
        
        for (index, dayOffset) in (0..<days).reversed().enumerated() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Calculate total sleep for this day
            let dayEntries = sleepEntries.filter { entry in
                guard let endTime = entry.endTime else { return false }
                return calendar.isDate(entry.startTime, inSameDayAs: date) && endTime > entry.startTime
            }
            
            let totalSeconds = dayEntries.reduce(0.0) { total, entry in
                guard let endTime = entry.endTime else { return total }
                return total + endTime.timeIntervalSince(entry.startTime)
            }
            
            let hours = totalSeconds / 3600.0
            let dayName = dayFormatter.string(from: date)
            let isToday = calendar.isDateInToday(date)
            
            data.append(DailySleepData(
                date: date,
                sleepHours: hours,
                dayName: dayName,
                isToday: isToday,
                index: index
            ))
        }
        
        return data
    }
    
    // Get sleep time data (Einschlafzeit) for specified period
    // Einschlafzeit = when the baby went to sleep in the EVENING of that day (18:00-23:59)
    func sleepTimeData(for period: StatisticsView.StatsPeriod) -> [DailyTimeData] {
        let today = calendar.startOfDay(for: Date())
        var data: [DailyTimeData] = []
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "de_DE")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let days: Int
        switch period {
        case .week:
            days = 7
            dayFormatter.dateFormat = "EEE"
        case .month:
            days = 30
            dayFormatter.dateFormat = "d"
        case .all:
            days = 7
            dayFormatter.dateFormat = "EEE"
        }
        
        for (index, dayOffset) in (0..<days).reversed().enumerated() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dayName = dayFormatter.string(from: date)
            let isToday = calendar.isDateInToday(date)
            
            // Find sleep entries that started in the EVENING of THIS day (18:00-23:59)
            let eveningEntries = sleepEntries.filter { entry in
                guard entry.endTime != nil else { return false }
                let hour = calendar.component(.hour, from: entry.startTime)
                return calendar.isDate(entry.startTime, inSameDayAs: date) && hour >= 18
            }.sorted { $0.startTime < $1.startTime }
            
            if let firstEntry = eveningEntries.first {
                let hour = calendar.component(.hour, from: firstEntry.startTime)
                let minute = calendar.component(.minute, from: firstEntry.startTime)
                let timeValue = Double(hour) + Double(minute) / 60.0
                
                data.append(DailyTimeData(
                    date: date,
                    timeValue: timeValue,
                    timeString: timeFormatter.string(from: firstEntry.startTime),
                    dayName: dayName,
                    isToday: isToday,
                    hasData: true,
                    index: index
                ))
            } else {
                data.append(DailyTimeData(
                    date: date,
                    timeValue: 0,
                    timeString: "--:--",
                    dayName: dayName,
                    isToday: isToday,
                    hasData: false,
                    index: index
                ))
            }
        }
        
        return data
    }
    
    // Get wake time data (Aufwachzeit) for specified period
    func wakeTimeData(for period: StatisticsView.StatsPeriod) -> [DailyTimeData] {
        let today = calendar.startOfDay(for: Date())
        var data: [DailyTimeData] = []
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "de_DE")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let days: Int
        switch period {
        case .week:
            days = 7
            dayFormatter.dateFormat = "EEE"
        case .month:
            days = 30
            dayFormatter.dateFormat = "d"
        case .all:
            days = 7
            dayFormatter.dateFormat = "EEE"
        }
        
        for (index, dayOffset) in (0..<days).reversed().enumerated() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Find the last wake time in the morning (typically end of night sleep)
            // Look for entries ending between 04:00 and 12:00
            let morningWakeEntries = sleepEntries.filter { entry in
                guard let endTime = entry.endTime else { return false }
                let endHour = calendar.component(.hour, from: endTime)
                
                // Check if wake time is in the morning of this day
                if calendar.isDate(endTime, inSameDayAs: date) && endHour >= 4 && endHour < 12 {
                    return true
                }
                
                return false
            }.sorted { ($0.endTime ?? Date()) < ($1.endTime ?? Date()) }
            
            let dayName = dayFormatter.string(from: date)
            let isToday = calendar.isDateInToday(date)
            
            // Take the first morning wake (end of night sleep)
            if let firstMorningEntry = morningWakeEntries.first, let endTime = firstMorningEntry.endTime {
                let hour = calendar.component(.hour, from: endTime)
                let minute = calendar.component(.minute, from: endTime)
                let timeValue = Double(hour) + Double(minute) / 60.0
                
                data.append(DailyTimeData(
                    date: date,
                    timeValue: timeValue,
                    timeString: timeFormatter.string(from: endTime),
                    dayName: dayName,
                    isToday: isToday,
                    hasData: true,
                    index: index
                ))
            } else {
                data.append(DailyTimeData(
                    date: date,
                    timeValue: 0,
                    timeString: "--:--",
                    dayName: dayName,
                    isToday: isToday,
                    hasData: false,
                    index: index
                ))
            }
        }
        
        return data
    }
    
    // Filter entries by period
    func entries(for period: StatisticsView.StatsPeriod) -> [SleepEntry] {
        let now = Date()
        
        switch period {
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
            return sleepEntries.filter { $0.startTime >= weekAgo && $0.endTime != nil }
        case .month:
            guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return [] }
            return sleepEntries.filter { $0.startTime >= monthAgo && $0.endTime != nil }
        case .all:
            return sleepEntries.filter { $0.endTime != nil }
        }
    }
    
    // Get unique days with sleep entries
    func uniqueDays(for period: StatisticsView.StatsPeriod) -> Int {
        let filteredEntries = entries(for: period)
        let days = Set(filteredEntries.map { calendar.startOfDay(for: $0.startTime) })
        return max(days.count, 1) // Avoid division by zero
    }
    
    // Calculate total sleep duration in seconds
    func totalSleepDuration(for period: StatisticsView.StatsPeriod) -> TimeInterval {
        let filteredEntries = entries(for: period)
        return filteredEntries.reduce(0) { total, entry in
            guard let endTime = entry.endTime else { return total }
            return total + endTime.timeIntervalSince(entry.startTime)
        }
    }
    
    // Calculate average daily sleep
    func averageDailySleep(for period: StatisticsView.StatsPeriod) -> (hours: Int, minutes: Int) {
        let totalSeconds = totalSleepDuration(for: period)
        let days = uniqueDays(for: period)
        
        guard days > 0 else { return (0, 0) }
        
        let averageSeconds = totalSeconds / Double(days)
        let hours = Int(averageSeconds) / 3600
        let minutes = (Int(averageSeconds) % 3600) / 60
        
        return (hours, minutes)
    }
    
    // Calculate average sleep sessions per day
    func averageSleepSessions(for period: StatisticsView.StatsPeriod) -> Double {
        let filteredEntries = entries(for: period)
        let days = uniqueDays(for: period)
        
        guard days > 0 else { return 0 }
        
        return Double(filteredEntries.count) / Double(days)
    }
    
    // Calculate average night sleep (sleep that starts between 18:00 and 23:59 or 00:00-06:00)
    func averageNightSleep(for period: StatisticsView.StatsPeriod) -> (hours: Int, minutes: Int) {
        let filteredEntries = entries(for: period)
        
        // Filter for night sleep entries
        let nightEntries = filteredEntries.filter { entry in
            let hour = calendar.component(.hour, from: entry.startTime)
            // Night sleep: starts between 18:00-23:59 or 00:00-06:00
            return hour >= 18 || hour < 6
        }
        
        guard !nightEntries.isEmpty else { return (0, 0) }
        
        // Group by night (entries from evening to next morning)
        var nightSleepDurations: [Date: TimeInterval] = [:]
        
        for entry in nightEntries {
            guard let endTime = entry.endTime else { continue }
            let duration = endTime.timeIntervalSince(entry.startTime)
            
            // Determine which "night" this belongs to
            let hour = calendar.component(.hour, from: entry.startTime)
            let nightDate: Date
            
            if hour >= 18 {
                // Evening entry - belongs to tonight
                nightDate = calendar.startOfDay(for: entry.startTime)
            } else {
                // Early morning entry - belongs to previous night
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: entry.startTime) {
                    nightDate = calendar.startOfDay(for: previousDay)
                } else {
                    nightDate = calendar.startOfDay(for: entry.startTime)
                }
            }
            
            nightSleepDurations[nightDate, default: 0] += duration
        }
        
        guard !nightSleepDurations.isEmpty else { return (0, 0) }
        
        let totalNightSleep = nightSleepDurations.values.reduce(0, +)
        let averageSeconds = totalNightSleep / Double(nightSleepDurations.count)
        
        let hours = Int(averageSeconds) / 3600
        let minutes = (Int(averageSeconds) % 3600) / 60
        
        return (hours, minutes)
    }
    
    // Helper: Calculate combined night sleep durations (combining entries that cross midnight)
    private func nightSleepDurations(for period: StatisticsView.StatsPeriod) -> [Date: TimeInterval] {
        let filteredEntries = entries(for: period)
        
        // Filter for night sleep entries (starting 18:00-23:59 or 00:00-06:00)
        let nightEntries = filteredEntries.filter { entry in
            let hour = calendar.component(.hour, from: entry.startTime)
            return hour >= 18 || hour < 6
        }
        
        // Group by night (entries from evening to next morning belong to the same night)
        var durations: [Date: TimeInterval] = [:]
        
        for entry in nightEntries {
            guard let endTime = entry.endTime else { continue }
            let duration = endTime.timeIntervalSince(entry.startTime)
            
            // Determine which "night" this belongs to
            let hour = calendar.component(.hour, from: entry.startTime)
            let nightDate: Date
            
            if hour >= 18 {
                // Evening entry - belongs to tonight (use evening's date as key)
                nightDate = calendar.startOfDay(for: entry.startTime)
            } else {
                // Early morning entry (00:00-06:00) - belongs to previous night
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: entry.startTime) {
                    nightDate = calendar.startOfDay(for: previousDay)
                } else {
                    nightDate = calendar.startOfDay(for: entry.startTime)
                }
            }
            
            durations[nightDate, default: 0] += duration
        }
        
        return durations
    }
    
    // Get longest sleep duration (considers combined night sleep)
    func longestSleep(for period: StatisticsView.StatsPeriod) -> (hours: Int, minutes: Int) {
        let filteredEntries = entries(for: period)
        
        // Get individual entry durations (for naps)
        let individualDurations = filteredEntries.compactMap { entry -> TimeInterval? in
            guard let endTime = entry.endTime else { return nil }
            let hour = calendar.component(.hour, from: entry.startTime)
            // Only include daytime naps (not night sleep entries which are combined separately)
            if hour >= 6 && hour < 18 {
                return endTime.timeIntervalSince(entry.startTime)
            }
            return nil
        }
        
        // Get combined night sleep durations
        let nightDurations = nightSleepDurations(for: period).values
        
        // Find the maximum from both individual naps and combined night sleeps
        let maxIndividual = individualDurations.max() ?? 0
        let maxNight = nightDurations.max() ?? 0
        let maxDuration = max(maxIndividual, maxNight)
        
        let hours = Int(maxDuration) / 3600
        let minutes = (Int(maxDuration) % 3600) / 60
        
        return (hours, minutes)
    }
    
    // Get shortest sleep duration (only considers individual entries, not combined nights)
    func shortestSleep(for period: StatisticsView.StatsPeriod) -> (hours: Int, minutes: Int) {
        let filteredEntries = entries(for: period)
        
        // For shortest, we look at individual entries (naps are typically the shortest)
        let minDuration = filteredEntries.compactMap { entry -> TimeInterval? in
            guard let endTime = entry.endTime else { return nil }
            return endTime.timeIntervalSince(entry.startTime)
        }.min() ?? 0
        
        let hours = Int(minDuration) / 3600
        let minutes = (Int(minDuration) % 3600) / 60
        
        return (hours, minutes)
    }
    
    // Get total entries count
    func totalEntries(for period: StatisticsView.StatsPeriod) -> Int {
        return entries(for: period).count
    }
    
    // Check if there's any data
    func hasData(for period: StatisticsView.StatsPeriod) -> Bool {
        return !entries(for: period).isEmpty
    }
    
    // Calculate average Einschlafzeit (average evening sleep start time)
    // Returns (hour, minute) tuple or nil if no data
    func averageEinschlafzeit() -> (hour: Int, minute: Int)? {
        // Get sleep time data for the last week
        let sleepTimeData = sleepTimeData(for: .week)
        let validData = sleepTimeData.filter { $0.hasData && !$0.isToday }
        
        guard !validData.isEmpty else { return nil }
        
        // Calculate average time value
        let totalTimeValue = validData.reduce(0.0) { $0 + $1.timeValue }
        let averageTimeValue = totalTimeValue / Double(validData.count)
        
        // Convert back to hour and minute
        let hour = Int(averageTimeValue)
        let minute = Int((averageTimeValue - Double(hour)) * 60)
        
        return (hour, minute)
    }
}

struct StatisticsView: View {
    @State private var selectedPeriod: StatsPeriod = .week
    @StateObject private var calculator = SleepStatisticsCalculator()
    
    enum StatsPeriod: String, CaseIterable {
        case week = "Woche"
        case month = "Monat"
        case all = "Gesamt"
    }
    
    // Computed statistics
    private var averageSleep: (hours: Int, minutes: Int) {
        calculator.averageDailySleep(for: selectedPeriod)
    }
    
    private var averageSessions: Double {
        calculator.averageSleepSessions(for: selectedPeriod)
    }
    
    private var averageNightSleep: (hours: Int, minutes: Int) {
        calculator.averageNightSleep(for: selectedPeriod)
    }
    
    private var longestSleep: (hours: Int, minutes: Int) {
        calculator.longestSleep(for: selectedPeriod)
    }
    
    private var shortestSleep: (hours: Int, minutes: Int) {
        calculator.shortestSleep(for: selectedPeriod)
    }
    
    private var hasData: Bool {
        calculator.hasData(for: selectedPeriod)
    }
    
    private var totalEntries: Int {
        calculator.totalEntries(for: selectedPeriod)
    }
    
    private var uniqueDays: Int {
        calculator.uniqueDays(for: selectedPeriod)
    }
    
    var body: some View {
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
                    Text("Statistik")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    // Period Picker
                    HStack(spacing: 8) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPeriod = period
                                }
                            }) {
                                Text(period.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(selectedPeriod == period ? Color(red: 0.55, green: 0.5, blue: 0.75) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    if hasData {
                        VStack(spacing: 16) {
                            // Summary info
                            HStack {
                                Text("\(totalEntries) Einträge")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                Text("\(uniqueDays) Tage")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.bottom, 8)
                            
                            // Sleep Chart (for week or month)
                            if selectedPeriod == .week || selectedPeriod == .month {
                                SleepDurationChart(
                                    data: calculator.chartData(for: selectedPeriod),
                                    period: selectedPeriod
                                )
                                
                                // Sleep Time Chart (Einschlafzeit)
                                SleepTimeChart(
                                    data: calculator.sleepTimeData(for: selectedPeriod),
                                    period: selectedPeriod
                                )
                                
                                // Wake Time Chart (Aufwachzeit)
                                WakeTimeChart(
                                    data: calculator.wakeTimeData(for: selectedPeriod),
                                    period: selectedPeriod
                                )
                            }
                            
                            // Average Daily Sleep Card
                            StatCard(
                                title: "Durchschnittlicher Schlaf pro Tag",
                                icon: "moon.fill",
                                iconColor: .indigo
                            ) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(averageSleep.hours)")
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("h")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("\(averageSleep.minutes)")
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("min")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            // Sleep Sessions Card
                            StatCard(
                                title: "Schlafphasen pro Tag",
                                icon: "repeat",
                                iconColor: .cyan
                            ) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", averageSessions))
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Nickerchen")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            // Night Sleep Card
                            StatCard(
                                title: "Durchschnittlicher Nachtschlaf",
                                icon: "moon.stars.fill",
                                iconColor: .purple
                            ) {
                                if averageNightSleep.hours > 0 || averageNightSleep.minutes > 0 {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("\(averageNightSleep.hours)")
                                            .font(.system(size: 42, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("h")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                        Text("\(averageNightSleep.minutes)")
                                            .font(.system(size: 42, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("min")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                } else {
                                    Text("Keine Nachtschlaf-Daten")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            
                            // Longest & Shortest Sleep
                            HStack(spacing: 12) {
                                // Longest Sleep
                                StatCardSmall(
                                    title: "Längster Schlaf",
                                    icon: "arrow.up.circle.fill",
                                    iconColor: .green,
                                    hours: longestSleep.hours,
                                    minutes: longestSleep.minutes
                                )
                                
                                // Shortest Sleep
                                StatCardSmall(
                                    title: "Kürzester Schlaf",
                                    icon: "arrow.down.circle.fill",
                                    iconColor: .orange,
                                    hours: shortestSleep.hours,
                                    minutes: shortestSleep.minutes
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    } else {
                        // No data message
                        VStack(spacing: 16) {
                            Image(systemName: "moon.zzz")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.2))
                            
                            Text("Noch keine Daten")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Füge Schlafeinträge hinzu, um Statistiken zu sehen.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 100)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            calculator.loadEntries()
        }
    }
}

// MARK: - Stat Card
struct StatCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Stat Card Small (for side-by-side display)
struct StatCardSmall: View {
    let title: String
    let icon: String
    let iconColor: Color
    let hours: Int
    let minutes: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(hours)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("h")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(minutes)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("m")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Sleep Duration Chart (supports week and month)
struct SleepDurationChart: View {
    let data: [DailySleepData]
    let period: StatisticsView.StatsPeriod
    
    private var maxSleepHours: Double {
        max(data.map { $0.sleepHours }.max() ?? 12, 12)
    }
    
    private var averageSleepHours: Double {
        // Only include days with entries and exclude today
        let daysWithData = data.filter { !$0.isToday && $0.sleepHours > 0 }
        guard !daysWithData.isEmpty else { return 0 }
        let total = daysWithData.reduce(0) { $0 + $1.sleepHours }
        return total / Double(daysWithData.count)
    }
    
    private var chartTitle: String {
        switch period {
        case .week:
            return "Schlaf der letzten 7 Tage"
        case .month:
            return "Schlaf der letzten 30 Tage"
        case .all:
            return "Schlaf"
        }
    }
    
    private var isMonthView: Bool {
        period == .month
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Text(chartTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            // Average label above chart
            if averageSleepHours > 0 {
                HStack {
                    Spacer()
                    Text("Ø \(String(format: "%.1f", averageSleepHours))h")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Chart
            Chart {
                // Average line (without annotation, label is above)
                if averageSleepHours > 0 {
                    RuleMark(y: .value("Durchschnitt", averageSleepHours))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                
                // Bars - use dayName for week (categorical), index for month (numeric)
                ForEach(data) { item in
                    if isMonthView {
                        BarMark(
                            x: .value("Tag", item.index),
                            y: .value("Stunden", item.sleepHours)
                        )
                        .foregroundStyle(Color(red: 0.45, green: 0.4, blue: 0.65))
                        .cornerRadius(3)
                    } else {
                        BarMark(
                            x: .value("Tag", item.dayName),
                            y: .value("Stunden", item.sleepHours)
                        )
                        .foregroundStyle(
                            item.isToday 
                                ? Color(red: 0.6, green: 0.5, blue: 0.85)
                                : Color(red: 0.45, green: 0.4, blue: 0.65)
                        )
                        .cornerRadius(6)
                    }
                }
            }
            .chartYScale(domain: 0...maxSleepHours)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .chartXAxis {
                if isMonthView {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index >= 0, index < data.count {
                                Text(data[index].dayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                } else {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let dayName = value.as(String.self) {
                                Text(dayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Sleep Time Chart (Einschlafzeit) - supports week and month
struct SleepTimeChart: View {
    let data: [DailyTimeData]
    let period: StatisticsView.StatsPeriod
    
    private var dataWithEntries: [DailyTimeData] {
        data.filter { $0.hasData }
    }
    
    private var minTime: Double {
        let times = dataWithEntries.map { $0.timeValue }
        let minVal = times.min() ?? 19
        return floor(minVal) - 0.5
    }
    
    private var maxTime: Double {
        let times = dataWithEntries.map { $0.timeValue }
        let maxVal = times.max() ?? 21
        return ceil(maxVal) + 0.5
    }
    
    private var averageTime: Double {
        let validData = dataWithEntries.filter { !$0.isToday }
        guard !validData.isEmpty else { return 0 }
        let total = validData.reduce(0) { $0 + $1.timeValue }
        return total / Double(validData.count)
    }
    
    private var isMonthView: Bool {
        period == .month
    }
    
    private func formatTimeLabel(_ value: Double) -> String {
        let hour = Int(value) % 24
        return String(format: "%02d:00", hour)
    }
    
    private func formatAverageTime(_ value: Double) -> String {
        let hour = Int(value) % 24
        let minute = Int((value - Double(Int(value))) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.indigo)
                }
                
                Text("Einschlafzeit")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            if dataWithEntries.isEmpty {
                Text("Keine Nachtschlaf-Daten")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                // Average time label above chart
                if averageTime > 0 {
                    HStack {
                        Spacer()
                        Text("Ø \(formatAverageTime(averageTime))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Chart
                Chart {
                    // Average line (without annotation, label is above)
                    if averageTime > 0 {
                        RuleMark(y: .value("Durchschnitt", averageTime))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    
                    // All days on X axis, but only show bars for days with data
                    ForEach(data) { item in
                        if isMonthView {
                            if item.hasData {
                                BarMark(
                                    x: .value("Tag", item.index),
                                    yStart: .value("Start", minTime),
                                    yEnd: .value("Zeit", item.timeValue)
                                )
                                .foregroundStyle(Color.indigo.opacity(0.7))
                                .cornerRadius(2)
                            } else {
                                PointMark(
                                    x: .value("Tag", item.index),
                                    y: .value("Zeit", minTime)
                                )
                                .opacity(0)
                            }
                        } else {
                            if item.hasData {
                                BarMark(
                                    x: .value("Tag", item.dayName),
                                    yStart: .value("Start", minTime),
                                    yEnd: .value("Zeit", item.timeValue)
                                )
                                .foregroundStyle(Color.indigo.opacity(0.7))
                                .cornerRadius(6)
                            } else {
                                PointMark(
                                    x: .value("Tag", item.dayName),
                                    y: .value("Zeit", minTime)
                                )
                                .opacity(0)
                            }
                        }
                    }
                }
                .chartYScale(domain: minTime...maxTime)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: 1)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let hours = value.as(Double.self), hours == floor(hours) {
                                Text(formatTimeLabel(hours))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .chartXAxis {
                    if isMonthView {
                        AxisMarks(values: .stride(by: 3)) { value in
                            AxisValueLabel {
                                if let index = value.as(Int.self), index >= 0, index < data.count {
                                    Text(data[index].dayName)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    } else {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel {
                                if let dayName = value.as(String.self) {
                                    Text(dayName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Wake Time Chart (Aufwachzeit) - supports week and month
struct WakeTimeChart: View {
    let data: [DailyTimeData]
    let period: StatisticsView.StatsPeriod
    
    private var dataWithEntries: [DailyTimeData] {
        data.filter { $0.hasData }
    }
    
    private var minTime: Double {
        let times = dataWithEntries.map { $0.timeValue }
        let minVal = times.min() ?? 6
        return floor(minVal) - 0.5
    }
    
    private var maxTime: Double {
        let times = dataWithEntries.map { $0.timeValue }
        let maxVal = times.max() ?? 8
        return ceil(maxVal) + 0.5
    }
    
    private var averageTime: Double {
        let validData = dataWithEntries.filter { !$0.isToday }
        guard !validData.isEmpty else { return 0 }
        let total = validData.reduce(0) { $0 + $1.timeValue }
        return total / Double(validData.count)
    }
    
    private var isMonthView: Bool {
        period == .month
    }
    
    private func formatTimeLabel(_ value: Double) -> String {
        let hour = Int(value)
        return String(format: "%02d:00", hour)
    }
    
    private func formatAverageTime(_ value: Double) -> String {
        let hour = Int(value)
        let minute = Int((value - Double(Int(value))) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Text("Aufwachzeit")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            if dataWithEntries.isEmpty {
                Text("Keine Aufwach-Daten")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                // Average time label above chart
                if averageTime > 0 {
                    HStack {
                        Spacer()
                        Text("Ø \(formatAverageTime(averageTime))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Chart
                Chart {
                    // Average line (without annotation, label is above)
                    if averageTime > 0 {
                        RuleMark(y: .value("Durchschnitt", averageTime))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    
                    // All days on X axis, but only show bars for days with data
                    ForEach(data) { item in
                        if isMonthView {
                            if item.hasData {
                                BarMark(
                                    x: .value("Tag", item.index),
                                    yStart: .value("Start", minTime),
                                    yEnd: .value("Zeit", item.timeValue)
                                )
                                .foregroundStyle(Color.orange.opacity(0.7))
                                .cornerRadius(2)
                            } else {
                                PointMark(
                                    x: .value("Tag", item.index),
                                    y: .value("Zeit", minTime)
                                )
                                .opacity(0)
                            }
                        } else {
                            if item.hasData {
                                BarMark(
                                    x: .value("Tag", item.dayName),
                                    yStart: .value("Start", minTime),
                                    yEnd: .value("Zeit", item.timeValue)
                                )
                                .foregroundStyle(Color.orange.opacity(0.7))
                                .cornerRadius(6)
                            } else {
                                PointMark(
                                    x: .value("Tag", item.dayName),
                                    y: .value("Zeit", minTime)
                                )
                                .opacity(0)
                            }
                        }
                    }
                }
                .chartYScale(domain: minTime...maxTime)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: 1)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let hours = value.as(Double.self), hours == floor(hours) {
                                Text(formatTimeLabel(hours))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .chartXAxis {
                    if isMonthView {
                        AxisMarks(values: .stride(by: 3)) { value in
                            AxisValueLabel {
                                if let index = value.as(Int.self), index >= 0, index < data.count {
                                    Text(data[index].dayName)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    } else {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel {
                                if let dayName = value.as(String.self) {
                                    Text(dayName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    StatisticsView()
}
