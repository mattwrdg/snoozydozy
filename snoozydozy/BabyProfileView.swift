//
//  BabyProfileView.swift
//  snoozydozy
//
//  Created by Matthias on 21.01.26.
//

import SwiftUI

struct BabyProfileView: View {
    @StateObject private var profileManager = BabyProfileManager.shared
    
    var body: some View {
        BabyProfileDetailView(
            hideProgressBar: true,
            hideTitle: true,
            hideWeiterButton: true
        )
    }
}

#Preview {
    BabyProfileView()
}
