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
                    .foregroundColor(Color(UIColor.systemGray2))
                
                
                if let iconName = appIconName(),
                   let uiImage = UIImage(named: iconName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 45, height: 45)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func appIconName() -> String? {
        guard let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last else {
            return nil
        }
        return iconFileName
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView()
}
