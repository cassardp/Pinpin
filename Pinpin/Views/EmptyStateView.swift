//
//  EmptyStateView.swift
//  Pinpin
//
//  Vue d'état vide quand aucun contenu n'est partagé
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("NOTHING YET • START SHARING!")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.systemGray2))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView()
}
