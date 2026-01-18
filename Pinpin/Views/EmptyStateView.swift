//
//  EmptyStateView.swift
//  Pinpin
//
//  Vue d'état vide quand aucun contenu n'est partagé
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ZStack {
            Color.clear
                .containerRelativeFrame([.horizontal, .vertical])
            
            VStack(spacing: 16) {
                Text("NOTHING YET • START SHARING TO PINPIN!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView()
}
