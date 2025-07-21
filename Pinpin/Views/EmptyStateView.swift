//
//  EmptyStateView.swift
//  Neeed2
//
//  Vue d'état vide quand aucun contenu n'est partagé
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 20) {
                Spacer()

                Text("NOTHING YET • START SHARING!")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray2))

                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView()
}
