//
//  SettingsView.swift
//  Neeed2
//
//  Vue des paramètres de l'application
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Binding var isSwipingHorizontally: Bool
    @StateObject private var userPreferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingBackupManagement: Bool = false
    
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

                    // Ligne de séparation
                    Divider()
                        .background(Color.gray.opacity(0.1))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    SettingsToggleRow(
                        title: "Dev Mode",
                        subtitle: "Show Vision Analysis in context menu",
                        isOn: $userPreferences.devMode
                    )

                }
                .padding(.horizontal, 20)
                .padding(.top, 40)


                Spacer(minLength: 0)
                
                // Lien vers la gestion des sauvegardes
                Button {
                    showingBackupManagement = true
                } label: {
                    Text("Backup Management")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .disabled(isSwipingHorizontally)
            .sheet(isPresented: $showingBackupManagement) {
                BackupManagementView(onOperationComplete: {
                    showingBackupManagement = false
                })
                    .presentationDetents([.fraction(0.5)])
            }
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
                    .fontWeight(.regular)
                
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
                .tint(Color(.systemGray))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .cornerRadius(12)
    }
}

// Simple UIKit wrapper to present the iOS share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(isSwipingHorizontally: .constant(false))
}
