//
//  BabyProfileDetailView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI

struct BabyProfileDetailView: View {
    @StateObject private var profileManager = BabyProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showDatePicker = false
    var hideProgressBar: Bool = false
    var hideTitle: Bool = false
    var hideWeiterButton: Bool = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.18)
                .ignoresSafeArea()
            
            // Stars
            StarFieldAnimated()
                .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // Progress Bar
                if !hideProgressBar {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(Color(red: 0.6, green: 0.5, blue: 0.75))
                                .frame(width: geometry.size.width * 0.75, height: 2)
                        }
                    }
                    .frame(height: 2)
                    .padding(.top, 8)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Section
                        if !hideTitle {
                            VStack(spacing: 8) {
                                Text("Ist das richtig?")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Fülle die Felder aus, damit wir bessere Vorhersagen machen können!")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 20)
                        } else {
                            // Header for tab view
                            HStack(spacing: 10) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Baby Profil")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        }
                        
                        // Profile Information Card
                        VStack(spacing: 0) {
                            BabyProfileTextFieldRow(
                                label: "Name",
                                value: Binding(
                                    get: { profileManager.profile.name },
                                    set: { newValue in
                                        var updated = profileManager.profile
                                        updated.name = newValue
                                        profileManager.profile = updated
                                    }
                                )
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            BabyProfileDateRow(
                                label: "Geburtstag",
                                date: Binding(
                                    get: { profileManager.profile.birthday },
                                    set: { newValue in
                                        var updated = profileManager.profile
                                        updated.birthday = newValue
                                        profileManager.profile = updated
                                    }
                                ),
                                formatter: dateFormatter,
                                showDatePicker: $showDatePicker
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            BabyProfilePickerRow(
                                label: "Geschlecht",
                                selection: Binding(
                                    get: { profileManager.profile.gender },
                                    set: { newValue in
                                        var updated = profileManager.profile
                                        updated.gender = newValue
                                        profileManager.profile = updated
                                    }
                                ),
                                options: ["Junge", "Mädchen"]
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            BabyProfilePickerRow(
                                label: "Stillen",
                                selection: Binding(
                                    get: { profileManager.profile.breastfeeding },
                                    set: { newValue in
                                        var updated = profileManager.profile
                                        updated.breastfeeding = newValue
                                        profileManager.profile = updated
                                    }
                                ),
                                options: ["Ja", "Nein"]
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            BabyProfileUnitRow(
                                label: "Größe",
                                value: Binding(
                                    get: { profileManager.profile.height },
                                    set: { newValue in
                                        var updated = profileManager.profile
                                        updated.height = newValue
                                        profileManager.profile = updated
                                    }
                                ),
                                unit: "cm"
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            BabyProfileUnitRow(
                                label: "Gewicht",
                                value: Binding(
                                    get: { profileManager.profile.weight },
                                    set: { newValue in
                                        var updated = profileManager.profile
                                        updated.weight = newValue
                                        profileManager.profile = updated
                                    }
                                ),
                                unit: "g"
                            )
                        }
                        .background(
                            Color(red: 0.15, green: 0.15, blue: 0.28)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        if hideWeiterButton {
                            Spacer()
                                .frame(height: 100) // Space for tab bar
                        } else {
                            Spacer()
                                .frame(height: 40)
                        }
                    }
                    .padding(.bottom, hideWeiterButton ? 0 : 20)
                }
                
                // Weiter Button
                if !hideWeiterButton {
                    Button(action: {
                        dismiss()
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
                } else {
                    Spacer()
                        .frame(height: 100) // Space for tab bar
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                VStack {
                    DatePicker("", selection: Binding(
                        get: { profileManager.profile.birthday },
                        set: { newValue in
                            var updated = profileManager.profile
                            updated.birthday = newValue
                            profileManager.profile = updated
                        }
                    ), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .accentColor(Color(red: 0.6, green: 0.5, blue: 0.75))
                        .colorScheme(.dark)
                        .padding()
                    
                    Spacer()
                }
                .background(Color(red: 0.08, green: 0.08, blue: 0.18))
                .navigationTitle("Geburtstag")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.18), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            showDatePicker = false
                        }
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.75))
                    }
                }
            }
        }
    }
}

// MARK: - Baby Profile Text Field Row
struct BabyProfileTextFieldRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("", text: $value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Baby Profile Date Row
struct BabyProfileDateRow: View {
    let label: String
    @Binding var date: Date
    let formatter: DateFormatter
    @Binding var showDatePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: {
                showDatePicker = true
            }) {
                HStack {
                    Text(formatter.string(from: date))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Baby Profile Picker Row
struct BabyProfilePickerRow: View {
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

// MARK: - Baby Profile Unit Row
struct BabyProfileUnitRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 8) {
                TextField("", text: $value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Text(unit)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}


#Preview {
    BabyProfileDetailView()
}
