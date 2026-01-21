//
//  SleepTrackingView.swift
//  snoozydozy
//
//  Created by Matthias on 20.01.26.
//

import SwiftUI
import Combine

// Model for a sleep entry
struct SleepEntry: Identifiable, Codable {
    let id: UUID
    var startTime: Date
    var endTime: Date?  // nil means sleep is ongoing
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
    }
    
    // Check if sleep is still ongoing
    var isOngoing: Bool {
        endTime == nil
    }
    
    // Get effective end time (current time if ongoing)
    var effectiveEndTime: Date {
        endTime ?? Date()
    }
    
    // Helper to create time from hours and minutes
    static func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }
    
    // Convert time to angle for 24-hour clock circle
    // 12:00 (noon) = top (-90°), 00:00 (midnight) = bottom (90°)
    // Clock moves clockwise: 12:00 -> 15:00 -> 18:00 -> 21:00 -> 00:00 -> 03:00 -> 06:00 -> 09:00 -> 12:00
    static func timeToAngle(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        // Map 24 hours to 360 degrees, with 12:00 at top (-90°)
        // 12:00 = 0° (top), 18:00 = 90° (right), 00:00 = 180° (bottom), 06:00 = 270° (left)
        let angle = ((totalMinutes - 12 * 60) / (24 * 60)) * 360
        return angle - 90 // Adjust so 0° points up
    }
    
    var startAngle: Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)
        return SleepEntry.timeToAngle(hour: hour, minute: minute)
    }
    
    var endAngle: Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: effectiveEndTime)
        let minute = calendar.component(.minute, from: effectiveEndTime)
        return SleepEntry.timeToAngle(hour: hour, minute: minute)
    }
    
    // Get the time string for display
    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }
    
    var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: effectiveEndTime)
    }
}

// MARK: - Sleep Storage Manager
class SleepStorageManager {
    static let shared = SleepStorageManager()
    private let storageKey = "sleepEntries"
    
    private init() {}
    
    func save(_ entries: [SleepEntry]) {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func load() -> [SleepEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([SleepEntry].self, from: data) else {
            return []
        }
        return entries
    }
}

// MARK: - Sunrise Sunset Service
struct SunriseSunsetResponse: Codable {
    let results: SunriseSunsetResults
    let status: String
}

struct SunriseSunsetResults: Codable {
    let sunrise: String
    let sunset: String
    let solar_noon: String
    let day_length: Int  // When formatted=0, this is seconds as integer
    let civil_twilight_begin: String
    let civil_twilight_end: String
}

struct SunTimes {
    let sunrise: Date
    let sunset: Date
    
    // Default times as fallback
    static let defaultTimes = SunTimes(
        sunrise: SleepEntry.createTime(hour: 7, minute: 0),
        sunset: SleepEntry.createTime(hour: 19, minute: 0)
    )
}

class SunriseSunsetService: ObservableObject {
    static let shared = SunriseSunsetService()
    
    @Published var sunTimes: SunTimes = SunTimes.defaultTimes
    @Published var isLoading = false
    
    // Karlsruhe coordinates
    private let latitude = 49.015429
    private let longitude = 8.0977275
    private let timezone = "Europe/Berlin"
    
    private var cachedDate: Date?
    
    private init() {}
    
    func fetchSunTimes(for date: Date) {
        let calendar = Calendar.current
        
        // Check if we already have data for this date
        if let cached = cachedDate, calendar.isDate(cached, inSameDayAs: date) {
            return
        }
        
        isLoading = true
        cachedDate = nil // Reset cache while loading
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Use tzid parameter to get local time directly
        let urlString = "https://api.sunrise-sunset.org/json?lat=\(latitude)&lng=\(longitude)&date=\(dateString)&formatted=0&tzid=\(timezone)"
        
        print("Fetching sun times from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data, error == nil else {
                    print("Error fetching sun times: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(SunriseSunsetResponse.self, from: data)
                    print("Status: \(response.status)")
                    print("Sunrise string: \(response.results.sunrise)")
                    print("Sunset string: \(response.results.sunset)")
                    
                    if response.status == "OK" {
                        // Parse ISO 8601 dates
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        // Try with fractional seconds first
                        var sunriseDate = isoFormatter.date(from: response.results.sunrise)
                        var sunsetDate = isoFormatter.date(from: response.results.sunset)
                        
                        // Try without fractional seconds
                        if sunriseDate == nil || sunsetDate == nil {
                            isoFormatter.formatOptions = [.withInternetDateTime]
                            sunriseDate = isoFormatter.date(from: response.results.sunrise)
                            sunsetDate = isoFormatter.date(from: response.results.sunset)
                        }
                        
                        // Try with timezone offset format
                        if sunriseDate == nil || sunsetDate == nil {
                            let customFormatter = DateFormatter()
                            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
                            customFormatter.locale = Locale(identifier: "en_US_POSIX")
                            sunriseDate = customFormatter.date(from: response.results.sunrise)
                            sunsetDate = customFormatter.date(from: response.results.sunset)
                        }
                        
                        print("Parsed sunrise: \(String(describing: sunriseDate))")
                        print("Parsed sunset: \(String(describing: sunsetDate))")
                        
                        if let sunrise = sunriseDate, let sunset = sunsetDate {
                            self?.sunTimes = SunTimes(sunrise: sunrise, sunset: sunset)
                            self?.cachedDate = date
                            print("Successfully updated sun times!")
                        } else {
                            print("Failed to parse dates")
                        }
                    }
                } catch {
                    print("Error decoding sun times: \(error)")
                }
            }
        }.resume()
    }
    
    // Format time for display (using local timezone)
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // Get hour and minute components (using local timezone)
    func getTimeComponents(_ date: Date) -> (hour: Int, minute: Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return (calendar.component(.hour, from: date), calendar.component(.minute, from: date))
    }
}

struct SleepTrackingView: View {
    @State private var sleepEntries: [SleepEntry] = []
    @State private var showAddSleep = false
    @State private var showEditSleep = false
    @State private var selectedEntry: SleepEntry? = nil
    @State private var selectedDate: Date = Date()
    @State private var currentTime: Date = Date()
    @StateObject private var sunService = SunriseSunsetService.shared
    
    // Timer for updating ongoing sleep
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: selectedDate)
    }
    
    // Check if there's an ongoing sleep
    private var hasOngoingSleep: Bool {
        sleepEntries.contains { $0.isOngoing }
    }
    
    // Filter entries for selected date
    private var entriesForSelectedDate: [SleepEntry] {
        let calendar = Calendar.current
        return sleepEntries.filter { entry in
            calendar.isDate(entry.startTime, inSameDayAs: selectedDate)
        }
    }
    
    // Start a new sleep
    private func startSleep() {
        let newEntry = SleepEntry(startTime: Date(), endTime: nil)
        sleepEntries.append(newEntry)
        saveSleepEntries()
    }
    
    // End the ongoing sleep
    private func endSleep() {
        if let index = sleepEntries.firstIndex(where: { $0.isOngoing }) {
            sleepEntries[index].endTime = Date()
            saveSleepEntries()
        }
    }
    
    // Save entries to storage
    private func saveSleepEntries() {
        SleepStorageManager.shared.save(sleepEntries)
    }
    
    // Load entries from storage
    private func loadSleepEntries() {
        sleepEntries = SleepStorageManager.shared.load()
    }
    
    // Delete an entry
    private func deleteEntry(_ entry: SleepEntry) {
        sleepEntries.removeAll { $0.id == entry.id }
        saveSleepEntries()
    }
    
    // Update an entry
    private func updateEntry(_ entry: SleepEntry) {
        if let index = sleepEntries.firstIndex(where: { $0.id == entry.id }) {
            sleepEntries[index] = entry
            saveSleepEntries()
        }
    }
    
    // Handle tap on sleep entry
    private func onEntryTapped(_ entry: SleepEntry) {
        selectedEntry = entry
        showEditSleep = true
    }
    
    var body: some View {
        ZStack {
            // Sternenhimmel-Hintergrund
            Color(red: 0.08, green: 0.08, blue: 0.18)
                .ignoresSafeArea()
            
            // Sterne
            StarFieldAnimated()
                .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // Week Picker
                WeekPickerView(selectedDate: $selectedDate)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                
                // Selected date headline
                Text(formattedSelectedDate)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)
                
                // Circular Timeline
                CircularTimelineWithIndicators(
                    sleepEntries: entriesForSelectedDate,
                    currentTime: currentTime,
                    sunTimes: sunService.sunTimes,
                    onEntryTapped: onEntryTapped
                )
                    .frame(width: 380, height: 380)
                
                // Start/Stop Sleep Button
                if hasOngoingSleep {
                    Button(action: endSleep) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Aufwachen")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 160, height: 50)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.8))
                        )
                    }
                    .padding(.top, 20)
                } else {
                    Button(action: startSleep) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Einschlafen")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 160, height: 50)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.55, green: 0.5, blue: 0.75))
                        )
                    }
                    .padding(.top, 20)
                }
                
                // Add manual entry Button
                Button(action: {
                    showAddSleep = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color(red: 0.55, green: 0.5, blue: 0.75))
                        )
                }
                .padding(.top, 15)
                
                // Sleep entries list
                if entriesForSelectedDate.isEmpty {
                    Text("Keine Schlafeinträge")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 20)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(entriesForSelectedDate.sorted(by: { $0.startTime < $1.startTime })) { entry in
                                SleepEntryRow(entry: entry, currentTime: currentTime)
                                    .onTapGesture {
                                        onEntryTapped(entry)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                        .padding(.bottom, 20)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        // Swipe left (negative) = go forward one day
                        // Swipe right (positive) = go back one day
                        if horizontalAmount < -50 {
                            // Swipe left - next day
                            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = nextDay
                                }
                            }
                        } else if horizontalAmount > 50 {
                            // Swipe right - previous day
                            if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = previousDay
                                }
                            }
                        }
                    }
            )
            
        }
        .navigationBarBackButtonHidden(false)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadSleepEntries()
            sunService.fetchSunTimes(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            sunService.fetchSunTimes(for: newDate)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .sheet(isPresented: $showAddSleep) {
            AddSleepSheet(
                sleepEntries: $sleepEntries,
                isPresented: $showAddSleep,
                selectedDate: selectedDate,
                onSave: saveSleepEntries
            )
        }
        .sheet(isPresented: $showEditSleep) {
            if let entry = selectedEntry {
                EditSleepSheet(
                    entry: entry,
                    isPresented: $showEditSleep,
                    onUpdate: updateEntry,
                    onDelete: deleteEntry
                )
            }
        }
    }
}

// MARK: - Circular Timeline with Indicators
struct CircularTimelineWithIndicators: View {
    let sleepEntries: [SleepEntry]
    var currentTime: Date = Date()
    var sunTimes: SunTimes = SunTimes.defaultTimes
    var onEntryTapped: ((SleepEntry) -> Void)? = nil
    
    // Check if there's ongoing sleep
    private var ongoingSleep: SleepEntry? {
        sleepEntries.first { $0.isOngoing }
    }
    
    // Get sunrise time components (local timezone)
    private var sunriseComponents: (hour: Int, minute: Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return (calendar.component(.hour, from: sunTimes.sunrise), calendar.component(.minute, from: sunTimes.sunrise))
    }
    
    // Get sunset time components (local timezone)
    private var sunsetComponents: (hour: Int, minute: Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return (calendar.component(.hour, from: sunTimes.sunset), calendar.component(.minute, from: sunTimes.sunset))
    }
    
    // Format time for display (local timezone)
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // Calculate total sleep in seconds
    private var totalSleepSeconds: TimeInterval {
        sleepEntries.reduce(0) { total, entry in
            let duration = entry.effectiveEndTime.timeIntervalSince(entry.startTime)
            return total + duration
        }
    }
    
    // Get hours component
    private var sleepHours: Int {
        Int(totalSleepSeconds) / 3600
    }
    
    // Get minutes component
    private var sleepMinutes: Int {
        (Int(totalSleepSeconds) % 3600) / 60
    }
    
    // Get seconds component (for stopwatch display)
    private var sleepSeconds: Int {
        Int(totalSleepSeconds) % 60
    }
    
    // Get ongoing sleep duration
    private var ongoingDuration: TimeInterval {
        guard let ongoing = ongoingSleep else { return 0 }
        return currentTime.timeIntervalSince(ongoing.startTime)
    }
    
    private var ongoingHours: Int {
        Int(ongoingDuration) / 3600
    }
    
    private var ongoingMinutes: Int {
        (Int(ongoingDuration) % 3600) / 60
    }
    
    private var ongoingSeconds: Int {
        Int(ongoingDuration) % 60
    }
    
    // Calculate position for a given hour on the 24-hour circle
    private func positionForTime(hour: Int, minute: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = SleepEntry.timeToAngle(hour: hour, minute: minute)
        let radians = CGFloat(angle * .pi / 180)
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 50
            
            ZStack {
                // Outer dotted circle (main timeline)
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 6]))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: radius * 2, height: radius * 2)
                
                // Small dots around the circle (every 30 minutes)
                ForEach(0..<48, id: \.self) { index in
                    let hour = index / 2
                    let minute = (index % 2) * 30
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 3, height: 3)
                        .position(positionForTime(hour: hour, minute: minute, radius: radius + 20, center: center))
                }
                
                // Sleep entries with labels (tappable)
                ForEach(sleepEntries) { entry in
                    SleepArcWithLabel(entry: entry, radius: radius, center: center)
                        .onTapGesture {
                            onEntryTapped?(entry)
                        }
                }
                
                // Center area (darker gradient)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.22),
                                Color(red: 0.08, green: 0.08, blue: 0.18)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius * 0.6
                        )
                    )
                    .frame(width: radius * 1.2, height: radius * 1.2)
                
                // Total sleep time in center
                VStack(spacing: 4) {
                    if ongoingSleep != nil {
                        // Stopwatch display for ongoing sleep
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%02d", ongoingHours))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text(":")
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Text(String(format: "%02d", ongoingMinutes))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text(":")
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Text(String(format: "%02d", ongoingSeconds))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Schläft gerade...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        // Normal total sleep display
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(sleepHours)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("h")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(sleepMinutes)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("min")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Text("Schlaf")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .position(center)
                
                // Sunrise indicator
                SunriseIndicator(time: formatTime(sunTimes.sunrise))
                    .position(positionForTime(hour: sunriseComponents.hour, minute: sunriseComponents.minute, radius: radius + 10, center: center))
                
                // Sunset indicator
                SunsetIndicator(time: formatTime(sunTimes.sunset))
                    .position(positionForTime(hour: sunsetComponents.hour, minute: sunsetComponents.minute, radius: radius + 10, center: center))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Sleep Arc with Label
struct SleepArcWithLabel: View {
    let entry: SleepEntry
    let radius: CGFloat
    let center: CGPoint
    
    // Color based on whether sleep is ongoing
    private var arcColor: Color {
        entry.isOngoing ? Color.green.opacity(0.6) : Color(red: 0.35, green: 0.4, blue: 0.6).opacity(0.8)
    }
    
    var body: some View {
        let midAngle = (entry.startAngle + entry.endAngle) / 2
        let iconPosition = pointOnCircle(angle: midAngle, radius: radius, center: center)
        
        ZStack {
            // Dashed arc background - drawn on the circle
            Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(entry.startAngle),
                    endAngle: .degrees(entry.endAngle),
                    clockwise: false
                )
            }
            .stroke(
                arcColor,
                style: StrokeStyle(lineWidth: 40, lineCap: .round, dash: [3, 4])
            )
            
            // Icon in the middle of the arc
            Image(systemName: entry.isOngoing ? "zzz" : "cloud.moon.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.9))
                .position(iconPosition)
            
            // Time labels - positioned outside the arc
            TimeLabel(time: entry.startTimeString)
                .position(pointOnCircle(angle: entry.startAngle, radius: radius + 30, center: center))
            
            if !entry.isOngoing {
                TimeLabel(time: entry.endTimeString)
                    .position(pointOnCircle(angle: entry.endAngle, radius: radius + 30, center: center))
            }
        }
    }
    
    private func pointOnCircle(angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = CGFloat(angle * .pi / 180)
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }
}

// MARK: - Time Label
struct TimeLabel: View {
    let time: String
    
    var body: some View {
        Text(time)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Sleep Entry Row
struct SleepEntryRow: View {
    let entry: SleepEntry
    var currentTime: Date = Date()
    
    // Calculate duration
    private var duration: TimeInterval {
        entry.effectiveEndTime.timeIntervalSince(entry.startTime)
    }
    
    private var durationHours: Int {
        Int(duration) / 3600
    }
    
    private var durationMinutes: Int {
        (Int(duration) % 3600) / 60
    }
    
    private var durationSeconds: Int {
        Int(duration) % 60
    }
    
    private var durationString: String {
        if entry.isOngoing {
            return String(format: "%02d:%02d:%02d", durationHours, durationMinutes, durationSeconds)
        } else {
            if durationHours > 0 {
                return "\(durationHours)h \(durationMinutes)min"
            } else {
                return "\(durationMinutes)min"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(entry.isOngoing ? Color.green.opacity(0.2) : Color(red: 0.35, green: 0.4, blue: 0.6).opacity(0.3))
                    .frame(width: 44, height: 44)
                
                Image(systemName: entry.isOngoing ? "zzz" : "moon.fill")
                    .font(.system(size: 18))
                    .foregroundColor(entry.isOngoing ? .green : Color(red: 0.7, green: 0.7, blue: 0.9))
            }
            
            // Time range
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.startTimeString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if entry.isOngoing {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("läuft...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(entry.endTimeString)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Text("Dauer: \(durationString)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(entry.isOngoing ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Week Picker View
struct WeekPickerView: View {
    @Binding var selectedDate: Date
    @State private var weekOffset: Int = 0
    
    private let calendar = Calendar.current
    
    // Get the days of the displayed week based on offset
    private var weekDays: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // Adjust to start from Monday (weekday 2 in Calendar)
        let daysFromMonday = (weekday + 5) % 7
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let monday = calendar.date(byAdding: .day, value: weekOffset * 7, to: thisMonday) else {
            return []
        }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monday)
        }
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEEE" // Single letter day
        return formatter.string(from: date)
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func previousWeek() {
        weekOffset -= 1
    }
    
    private func nextWeek() {
        weekOffset += 1
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Previous week button
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 30, height: 55)
            }
            
            // Days of the week
            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack(spacing: 4) {
                            Text(dayLetter(for: date))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isSelected(date) ? .white : .white.opacity(0.5))
                            
                            Text(dayNumber(for: date))
                                .font(.system(size: 16, weight: isSelected(date) ? .bold : .medium))
                                .foregroundColor(isSelected(date) ? .white : .white.opacity(0.7))
                        }
                        .frame(width: 38, height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected(date) ? Color(red: 0.55, green: 0.5, blue: 0.75) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday(date) && !isSelected(date) ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
            
            // Next week button
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 30, height: 55)
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Sunrise Indicator
struct SunriseIndicator: View {
    var time: String = "07:00"
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.8), lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }
            
            Text(time)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Sunset Indicator
struct SunsetIndicator: View {
    var time: String = "19:00"
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "sunset.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
            
            Text(time)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Static Star Field
struct StarFieldAnimated: View {
    // Pre-computed star positions using seeded random
    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = {
        var result: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = []
        for i in 0..<80 {
            // Use deterministic values based on index
            let x = CGFloat((i * 17 + 23) % 100) / 100.0
            let y = CGFloat((i * 31 + 47) % 100) / 100.0
            let size = CGFloat(1.0 + Double(i % 3) * 0.5)
            let opacity = 0.3 + Double(i % 5) * 0.15
            result.append((x, y, size, opacity))
        }
        return result
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<stars.count, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: stars[index].size)
                    .opacity(stars[index].opacity)
                    .position(
                        x: stars[index].x * geometry.size.width,
                        y: stars[index].y * geometry.size.height
                    )
            }
        }
    }
}

// MARK: - Add Sleep Sheet
struct AddSleepSheet: View {
    @Binding var sleepEntries: [SleepEntry]
    @Binding var isPresented: Bool
    let selectedDate: Date
    var onSave: (() -> Void)? = nil
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    // Combine selected date with picked time
    private func combineDateWithTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = 0
        
        return calendar.date(from: combined) ?? date
    }
    
    // Format selected date for display
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.15, green: 0.15, blue: 0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Selected date info
                    Text(formattedDate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 8)
                    
                    // Start Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eingeschlafen")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.25, green: 0.2, blue: 0.35))
                            .cornerRadius(12)
                    }
                    
                    // End Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aufgewacht")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.25, green: 0.2, blue: 0.35))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        let calendar = Calendar.current
                        let actualStartTime = combineDateWithTime(date: selectedDate, time: startTime)
                        let actualEndTime = combineDateWithTime(date: selectedDate, time: endTime)
                        
                        // Check if sleep crosses midnight (end time hour is before start time hour)
                        let startHour = calendar.component(.hour, from: startTime)
                        let endHour = calendar.component(.hour, from: endTime)
                        let startMinute = calendar.component(.minute, from: startTime)
                        let endMinute = calendar.component(.minute, from: endTime)
                        
                        let startTotalMinutes = startHour * 60 + startMinute
                        let endTotalMinutes = endHour * 60 + endMinute
                        
                        if endTotalMinutes <= startTotalMinutes {
                            // Sleep crosses midnight - create two entries
                            
                            // Entry 1: Start time to 23:59 on selected date
                            var endOfDayComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                            endOfDayComponents.hour = 23
                            endOfDayComponents.minute = 59
                            endOfDayComponents.second = 59
                            if let endOfDay = calendar.date(from: endOfDayComponents) {
                                let entry1 = SleepEntry(startTime: actualStartTime, endTime: endOfDay)
                                sleepEntries.append(entry1)
                            }
                            
                            // Entry 2: 00:00 to end time on next day
                            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                                var startOfNextDayComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
                                startOfNextDayComponents.hour = 0
                                startOfNextDayComponents.minute = 0
                                startOfNextDayComponents.second = 0
                                
                                var endOnNextDayComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
                                endOnNextDayComponents.hour = endHour
                                endOnNextDayComponents.minute = endMinute
                                endOnNextDayComponents.second = 0
                                
                                if let startOfNextDay = calendar.date(from: startOfNextDayComponents),
                                   let endOnNextDay = calendar.date(from: endOnNextDayComponents) {
                                    let entry2 = SleepEntry(startTime: startOfNextDay, endTime: endOnNextDay)
                                    sleepEntries.append(entry2)
                                }
                            }
                        } else {
                            // Normal entry within same day
                            let newEntry = SleepEntry(startTime: actualStartTime, endTime: actualEndTime)
                            sleepEntries.append(newEntry)
                        }
                        
                        onSave?()
                        isPresented = false
                    }) {
                        Text("Speichern")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(red: 0.6, green: 0.5, blue: 0.75)
                            )
                            .cornerRadius(16)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Schlaf hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 1.0))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Edit Sleep Sheet
struct EditSleepSheet: View {
    let entry: SleepEntry
    @Binding var isPresented: Bool
    var onUpdate: ((SleepEntry) -> Void)? = nil
    var onDelete: ((SleepEntry) -> Void)? = nil
    
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var showDeleteConfirmation = false
    
    init(entry: SleepEntry, isPresented: Binding<Bool>, onUpdate: ((SleepEntry) -> Void)? = nil, onDelete: ((SleepEntry) -> Void)? = nil) {
        self.entry = entry
        self._isPresented = isPresented
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._startTime = State(initialValue: entry.startTime)
        self._endTime = State(initialValue: entry.endTime ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.15, green: 0.15, blue: 0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Start Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eingeschlafen")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.25, green: 0.2, blue: 0.35))
                            .cornerRadius(12)
                    }
                    
                    // End Time (only if not ongoing)
                    if !entry.isOngoing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aufgewacht")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.25, green: 0.2, blue: 0.35))
                                .cornerRadius(12)
                        }
                    } else {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                            Text("Schlaf läuft noch...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        var updatedEntry = entry
                        updatedEntry.startTime = startTime
                        if !entry.isOngoing {
                            updatedEntry.endTime = endTime
                        }
                        onUpdate?(updatedEntry)
                        isPresented = false
                    }) {
                        Text("Speichern")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(red: 0.6, green: 0.5, blue: 0.75)
                            )
                            .cornerRadius(16)
                    }
                    
                    // Delete Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Löschen")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.red.opacity(0.15)
                            )
                            .cornerRadius(16)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Schlaf bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 1.0))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Schlaf löschen?", isPresented: $showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    onDelete?(entry)
                    isPresented = false
                }
            } message: {
                Text("Möchtest du diesen Schlafeintrag wirklich löschen?")
            }
        }
    }
}

#Preview {
    SleepTrackingView()
}
