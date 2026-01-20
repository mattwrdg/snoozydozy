//
//  ContentView.swift
//  snoozydozy
//
//  Created by Matthias on 20.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var showBabyInfo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Sternenhimmel-Hintergrund
                Color(red: 0.15, green: 0.15, blue: 0.3)
                    .ignoresSafeArea()
                
                // Sterne
                StarField()
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Name
                    Text("snoozy dozzy")
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    // Sleep Icon
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 120, weight: .light))
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                    
                    // Headline
                    VStack(spacing: 4) {
                        Text("Der schnellste Weg zu")
                            .font(.system(size: 22, weight: .medium))
                        Text("einem glücklich")
                            .font(.system(size: 22, weight: .medium))
                        Text("schlafenden Baby")
                            .font(.system(size: 22, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 50)
                    
                    Spacer()
                    
                    // Loslegen Button
                    Button(action: {
                        showBabyInfo = true
                    }) {
                        Text("loslegen")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(red: 0.6, green: 0.5, blue: 0.75)
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
            .navigationDestination(isPresented: $showBabyInfo) {
                BabyInfoView()
            }
        }
    }
}

// Sterne-Hintergrund
struct StarField: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: CGFloat.random(in: 1...2))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
            }
        }
    }
}

// Baby Info View
struct BabyInfoView: View {
    @State private var name = "Mobi"
    @State private var birthday = Date(timeIntervalSince1970: 1735689600) // January 1, 2026
    @State private var gender = "Junge"
    @State private var breastfeeding = "Ja"
    @State private var height = "52"
    @State private var weight = "3750"
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }
    
    var body: some View {
        ZStack {
            // Sternenhimmel-Hintergrund (gleich wie Welcome Page)
            Color(red: 0.15, green: 0.15, blue: 0.3)
                .ignoresSafeArea()
            
            // Sterne
            StarField()
                .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(Color(red: 0.6, green: 0.5, blue: 0.75))
                            .frame(width: geometry.size.width * 0.3, height: 2)
                    }
                }
                .frame(height: 2)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Titel
                        VStack(spacing: 8) {
                            Text("Ist das richtig?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Fülle die Felder aus, damit wir bessere Vorhersagen machen können!")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                        
                        // Daten-Karte
                        VStack(spacing: 0) {
                            BabyInfoRow(label: "Name", value: $name)
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            BabyInfoDateRow(label: "Geburtstag", date: $birthday, formatter: dateFormatter)
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            BabyInfoPickerRow(label: "Geschlecht", selection: $gender, options: ["Junge", "Mädchen"])
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            BabyInfoPickerRow(label: "Stillen", selection: $breastfeeding, options: ["Ja", "Nein"])
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            BabyInfoUnitRow(label: "Größe", value: $height, unit: "cm")
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            BabyInfoUnitRow(label: "Gewicht", value: $weight, unit: "g")
                        }
                        .background(
                            Color(red: 0.25, green: 0.2, blue: 0.35)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
                
                // Weiter Button
                Button(action: {
                    // Weiter Action
                }) {
                    Text("Weiter")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.5, blue: 0.75),
                                    Color(red: 0.5, green: 0.4, blue: 0.65)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// Baby Info Row Component
struct BabyInfoRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("", text: $value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// Baby Info Unit Row Component (for Größe and Gewicht)
struct BabyInfoUnitRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 4) {
                TextField("", text: $value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                Text(unit)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// Baby Info Date Row Component
struct BabyInfoDateRow: View {
    let label: String
    @Binding var date: Date
    let formatter: DateFormatter
    @State private var showDatePicker = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Button(action: {
                showDatePicker = true
            }) {
                Text(formatter.string(from: date))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                VStack {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .accentColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        .colorScheme(.dark)
                        .padding()
                    
                    Spacer()
                }
                .background(Color(red: 0.15, green: 0.15, blue: 0.3))
                .navigationTitle("Geburtstag")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            showDatePicker = false
                        }
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                }
            }
        }
    }
}

// Baby Info Picker Row Component
struct BabyInfoPickerRow: View {
    let label: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color(red: 0.6, green: 0.5, blue: 0.75))
            .colorScheme(.dark)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ContentView()
}
