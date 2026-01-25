//
//  PrivacyPolicyView.swift
//  snoozydozy
//
//  Created by Matthias on 23.01.26.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            AppColors.backgroundDark
                .ignoresSafeArea()
            
            // Stars
            StarFieldAnimated()
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Text("Datenschutzerklärung")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionView(title: "1. Verantwortlicher", content: """
                        Verantwortlicher für die Datenverarbeitung ist der Entwickler dieser App. Bei Fragen zum Datenschutz können Sie uns über die in der App angegebenen Kontaktmöglichkeiten erreichen.
                        """)
                        
                        SectionView(title: "2. Erhebung von Daten", content: """
                        Die App erhebt und speichert folgende Daten lokal auf Ihrem Gerät:
                        • Schlafzeiten und -dauer
                        • Baby-Profilinformationen (Name, Geburtsdatum)
                        • Einstellungen und Präferenzen
                        
                        Diese Daten werden ausschließlich auf Ihrem Gerät gespeichert und nicht an Dritte übertragen.
                        """)
                        
                        SectionView(title: "3. Zweck der Datenverarbeitung", content: """
                        Die erfassten Daten dienen ausschließlich der Funktionalität der App, insbesondere:
                        • Dokumentation von Schlafmustern
                        • Berechnung von Statistiken und Durchschnittswerten
                        • Erinnerungen und Benachrichtigungen
                        • Personalisierung der App-Nutzung
                        """)
                        
                        SectionView(title: "4. Lokale Datenspeicherung", content: """
                        Alle Daten werden lokal auf Ihrem Gerät gespeichert. Wir haben keinen Zugriff auf Ihre Daten. Die Daten werden nicht an Server übertragen oder in Cloud-Diensten gespeichert, es sei denn, Sie nutzen explizit iCloud-Backup-Funktionen Ihres Geräts.
                        """)
                        
                        SectionView(title: "5. Benachrichtigungen", content: """
                        Die App kann lokale Benachrichtigungen senden, um Sie an Schlafenszeiten zu erinnern. Diese Benachrichtigungen werden lokal auf Ihrem Gerät generiert und erfordern Ihre ausdrückliche Zustimmung.
                        """)
                        
                        SectionView(title: "6. Datenlöschung", content: """
                        Sie können alle gespeicherten Daten jederzeit über die App-Funktionen löschen. Beim Deinstallieren der App werden alle lokal gespeicherten Daten von Ihrem Gerät entfernt.
                        """)
                        
                        SectionView(title: "7. Rechte der betroffenen Person", content: """
                        Sie haben das Recht:
                        • Auskunft über Ihre gespeicherten Daten zu erhalten
                        • Berichtigung unrichtiger Daten zu verlangen
                        • Löschung Ihrer Daten zu verlangen
                        • Widerspruch gegen die Verarbeitung einzulegen
                        
                        Da alle Daten lokal gespeichert sind, können Sie diese Rechte direkt über die App-Funktionen ausüben.
                        """)
                        
                        SectionView(title: "8. Datensicherheit", content: """
                        Wir setzen technische und organisatorische Maßnahmen ein, um Ihre Daten zu schützen. Da die Daten lokal auf Ihrem Gerät gespeichert werden, hängt die Sicherheit auch von den Sicherheitseinstellungen Ihres Geräts ab.
                        """)
                        
                        SectionView(title: "9. Änderungen der Datenschutzerklärung", content: """
                        Wir behalten uns vor, diese Datenschutzerklärung zu aktualisieren, um sie an geänderte Rechtslagen oder Funktionalitäten der App anzupassen. Die aktuelle Version ist in der App einsehbar.
                        """)
                        
                        SectionView(title: "10. Kontakt", content: """
                        Bei Fragen zum Datenschutz oder zur Ausübung Ihrer Rechte können Sie uns über die in der App angegebenen Kontaktmöglichkeiten erreichen.
                        """)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    PrivacyPolicyView()
}
