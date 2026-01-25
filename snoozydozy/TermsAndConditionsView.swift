//
//  TermsAndConditionsView.swift
//  snoozydozy
//
//  Created by Matthias on 23.01.26.
//

import SwiftUI

struct TermsAndConditionsView: View {
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
                    
                    Text("Geschäftsbedingungen")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionView(title: "1. Geltungsbereich", content: """
                        Diese Geschäftsbedingungen gelten für die Nutzung der mobilen Anwendung "Snoozy Dozy" (nachfolgend "App" genannt). Durch die Installation und Nutzung der App akzeptieren Sie diese Bedingungen vollständig.
                        """)
                        
                        SectionView(title: "2. Leistungsbeschreibung", content: """
                        Die App bietet Funktionen zur Schlafverfolgung und -analyse für Babys. Die App dient als Hilfsmittel zur Dokumentation und Analyse von Schlafmustern und erhebt keinen Anspruch auf medizinische Genauigkeit oder Vollständigkeit.
                        """)
                        
                        SectionView(title: "3. Nutzungsrechte", content: """
                        Sie erhalten ein nicht-exklusives, nicht übertragbares Recht zur Nutzung der App auf Ihren persönlichen Geräten. Eine kommerzielle Nutzung oder Weitergabe der App ist nicht gestattet.
                        """)
                        
                        SectionView(title: "4. Datenschutz", content: """
                        Die Erhebung und Verarbeitung Ihrer Daten erfolgt gemäß unserer Datenschutzerklärung. Alle Daten werden lokal auf Ihrem Gerät gespeichert, sofern nicht ausdrücklich anders angegeben.
                        """)
                        
                        SectionView(title: "5. Verfügbarkeit", content: """
                        Wir bemühen uns um eine hohe Verfügbarkeit der App, können jedoch keine Garantie für eine unterbrechungsfreie Nutzung geben. Wartungsarbeiten können die Verfügbarkeit vorübergehend einschränken.
                        """)
                        
                        SectionView(title: "6. Änderungen der App", content: """
                        Wir behalten uns vor, die App jederzeit zu ändern, zu aktualisieren oder Funktionen hinzuzufügen oder zu entfernen. Sie sind nicht berechtigt, Änderungen an der App vorzunehmen.
                        """)
                        
                        SectionView(title: "7. Haftungsausschluss", content: """
                        Die App wird "wie besehen" bereitgestellt. Wir übernehmen keine Haftung für Schäden, die durch die Nutzung der App entstehen. Die App ersetzt keine medizinische Beratung.
                        """)
                        
                        SectionView(title: "8. Kündigung", content: """
                        Sie können die Nutzung der App jederzeit beenden, indem Sie die App von Ihrem Gerät entfernen. Wir behalten uns vor, die Bereitstellung der App jederzeit einzustellen.
                        """)
                        
                        SectionView(title: "9. Änderungen der Bedingungen", content: """
                        Wir behalten uns vor, diese Geschäftsbedingungen jederzeit zu ändern. Änderungen werden in der App veröffentlicht. Die fortgesetzte Nutzung der App nach Veröffentlichung von Änderungen gilt als Zustimmung zu den geänderten Bedingungen.
                        """)
                        
                        SectionView(title: "10. Schlussbestimmungen", content: """
                        Sollten einzelne Bestimmungen dieser Geschäftsbedingungen unwirksam sein, bleibt die Wirksamkeit der übrigen Bestimmungen unberührt. Es gilt deutsches Recht.
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

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TermsAndConditionsView()
}
