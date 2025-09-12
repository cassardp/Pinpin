//
//  SettingsView.swift
//  Neeed2
//
//  Vue des paramètres de l'application
//

import SwiftUI

struct SettingsView: View {
    @Binding var isSwipingHorizontally: Bool
    @StateObject private var userPreferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        title: "Show Cards URLs",
                        subtitle: "",
                        isOn: $userPreferences.showURLs
                    )

                    // Ligne de séparation
                    Divider()
                        .background(Color.gray.opacity(0.1))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    SettingsToggleRow(
                        title: "Square Cards",
                        subtitle: "",
                        isOn: $userPreferences.disableCornerRadius
                    )

                    // Ligne de séparation
                    Divider()
                        .background(Color.gray.opacity(0.1))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    SettingsToggleRow(
                        title: "Force Dark mode",
                        subtitle: "",
                        isOn: $userPreferences.forceDarkMode
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .disabled(isSwipingHorizontally)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                isOn.toggle()
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView(isSwipingHorizontally: .constant(false))
}
