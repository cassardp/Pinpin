//
//  SettingsView.swift
//  Pinpin
//
//  Vue des paramètres de l'application
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var dataService = DataService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
                        title: colorScheme == .dark ? "Force Light Mode" : "Force Dark Mode",
                        subtitle: "",
                        isOn: $userPreferences.forceDarkMode
                    )

                }
                .padding(.horizontal, 20)
                .padding(.top, 40)

                // iCloud Sync Status Section
                
                Spacer(minLength: 0)
                
                VStack(spacing: 0) {
                    
                    // Sync Status Row
                    HStack {
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: getSyncIcon())
                                    .foregroundColor(getSyncColor())
                                    .font(.system(size: 16))
                                
                                Text("iCloud")
                                    .font(.body)
                                    .fontWeight(.regular)
                            }
                            
                            Text(dataService.getiCloudSyncStatus())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if dataService.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }

                
                // Lien vers la gestion des sauvegardes
                Button {
                    showingBackupManagement = true
                } label: {
                    Text("Manual Backup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .sheet(isPresented: $showingBackupManagement) {
                BackupManagementView(onOperationComplete: {
                    showingBackupManagement = false
                })
                    .presentationDetents([.fraction(0.5)])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSyncIcon() -> String {
        if !dataService.isiCloudAvailable {
            return "exclamationmark.triangle.fill"
        } else if dataService.isiCloudSyncUpToDate() {
            return "checkmark.circle.fill"
        } else {
            return "arrow.triangle.2.circlepath"
        }
    }
    
    private func getSyncColor() -> Color {
        if !dataService.isiCloudAvailable {
            return .red
        } else if dataService.isiCloudSyncUpToDate() {
            return .green
        } else {
            return .orange
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
                .tint(Color(.green))
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
    SettingsView()
}
