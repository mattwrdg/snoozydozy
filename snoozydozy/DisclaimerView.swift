//
//  DisclaimerView.swift
//  snoozydozy
//
//  Created by Matthias on 23.01.26.
//

import SwiftUI

struct DisclaimerView: View {
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
                    
                    Text("Haftungsausschluss")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionView(title: "1. Allgemeiner Haftungsausschluss", content: """
                        Die Inhalte dieser App wurden mit größtmöglicher Sorgfalt erstellt. Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte können wir jedoch keine Gewähr übernehmen. Als Diensteanbieter sind wir für eigene Inhalte nach den allgemeinen Gesetzen verantwortlich.
                        """)
                        
                        SectionView(title: "2. Keine medizinische Beratung", content: """
                        Die App dient ausschließlich der Dokumentation und Analyse von Schlafmustern. Sie stellt keine medizinische, therapeutische oder diagnostische Beratung dar. Die App ersetzt nicht die Konsultation eines Arztes, Kinderarztes oder anderen medizinischen Fachpersonals.
                        
                        Bei gesundheitlichen Fragen oder Problemen wenden Sie sich bitte immer an einen qualifizierten Arzt oder medizinischen Fachmann.
                        """)
                        
                        SectionView(title: "3. Keine Garantie für Ergebnisse", content: """
                        Wir übernehmen keine Garantie dafür, dass die Nutzung der App zu bestimmten Ergebnissen führt. Die App ist ein Hilfsmittel zur Dokumentation und Analyse, kann jedoch individuelle Umstände nicht berücksichtigen.
                        """)
                        
                        SectionView(title: "4. Haftung für Schäden", content: """
                        Die Haftung für Schäden, die durch die Nutzung oder Nichtnutzbarkeit der App entstehen, ist ausgeschlossen, soweit gesetzlich zulässig. Dies gilt nicht für:
                        • Vorsätzliches oder grob fahrlässiges Verhalten
                        • Schäden aus der Verletzung des Lebens, des Körpers oder der Gesundheit
                        • Schäden aus der Verletzung wesentlicher Vertragspflichten
                        """)
                        
                        SectionView(title: "5. Verfügbarkeit der App", content: """
                        Wir übernehmen keine Gewähr für die ständige Verfügbarkeit der App. Wartungsarbeiten, technische Probleme oder andere Umstände können die Nutzung der App vorübergehend einschränken oder unmöglich machen.
                        """)
                        
                        SectionView(title: "6. Externe Links", content: """
                        Sollte die App Links zu externen Websites enthalten, haben wir keinen Einfluss auf deren Inhalte. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber verantwortlich.
                        """)
                        
                        SectionView(title: "7. Datenverlust", content: """
                        Wir übernehmen keine Haftung für den Verlust von Daten, die in der App gespeichert wurden. Wir empfehlen, regelmäßig Backups Ihrer Daten zu erstellen, falls die App entsprechende Funktionen bietet.
                        """)
                        
                        SectionView(title: "8. Gerätekompatibilität", content: """
                        Die App wurde für bestimmte Betriebssystemversionen entwickelt. Wir übernehmen keine Haftung für Probleme, die durch Inkompatibilitäten mit älteren oder neueren Versionen entstehen.
                        """)
                        
                        SectionView(title: "9. Änderungen der App", content: """
                        Wir behalten uns vor, die App jederzeit zu ändern, zu aktualisieren oder Funktionen zu entfernen. Wir übernehmen keine Haftung für Auswirkungen, die solche Änderungen auf Ihre Nutzung haben können.
                        """)
                        
                        SectionView(title: "10. Anwendung deutsches Recht", content: """
                        Es gilt deutsches Recht unter Ausschluss des UN-Kaufrechts. Gerichtsstand ist, soweit gesetzlich zulässig, der Sitz des Entwicklers.
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
    DisclaimerView()
}
