//
//  SettingsView.swift
//  Pinpin
//
//  Vue des paramètres de l'application
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable private var userPreferences = UserPreferences.shared
    @StateObject private var dataService = DataService.shared
    @StateObject private var cleanupService = CloudKitCleanupService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingBackupManagement: Bool = false
    @State private var showingCleanupConfirmation: Bool = false
    @State private var debugModeEnabled: Bool = false
    @State private var debugTapCount: Int = 0
    
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
                        title: "Hide Category Titles",
                        subtitle: "",
                        isOn: $userPreferences.hideCategoryTitles
                    )

                    // Ligne de séparation
                    Divider()
                        .background(Color.gray.opacity(0.1))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    SettingsToggleRow(
                        title: colorScheme == .dark ? "Light Mode" : "Dark Mode",
                        subtitle: "",
                        isOn: $userPreferences.forceDarkMode
                    )

                    // Ligne de séparation
                    Divider()
                        .background(Color.gray.opacity(0.1))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    SettingsToggleRow(
                        title: "Hide Timeline",
                        subtitle: "",
                        isOn: Binding(
                            get: { !userPreferences.showTimelineView },
                            set: { userPreferences.showTimelineView = !$0 }
                        )
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
                                    .onTapGesture {
                                        debugTapCount += 1
                                        if debugTapCount >= 5 {
                                            debugModeEnabled.toggle()
                                            debugTapCount = 0
                                        }
                                        // Reset après 2 secondes
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            debugTapCount = 0
                                        }
                                    }
                            }
                            
                            if cleanupService.isCleaningUp {
                                Text(cleanupService.cleanupProgress)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if let error = cleanupService.cleanupError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text(dataService.getiCloudSyncStatus())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if dataService.isSyncing || cleanupService.isCleaningUp {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    
                    // CloudKit Debug Tools (Mode Debug uniquement)
                    if dataService.isiCloudAvailable && debugModeEnabled {
                        VStack(spacing: 16) {
                            // Header
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                    .foregroundColor(.orange)
                                Text("Debug Tools")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 20)
                            
                            // Diagnostic buttons
                            VStack(spacing: 12) {
                                Button {
                                    Task {
                                        do {
                                            try await cleanupService.diagnoseSync()
                                        } catch {
                                            print("[SettingsView] ❌ Diagnostic error: \(error)")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "stethoscope")
                                            .font(.body)
                                        Text("Diagnose Sync")
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(cleanupService.isCleaningUp || dataService.isSyncing)
                                
                                Button {
                                    Task {
                                        do {
                                            try await cleanupService.removeDuplicateItems()
                                        } catch {
                                            print("[SettingsView] ❌ Remove duplicates error: \(error)")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.on.doc")
                                            .font(.body)
                                        Text("Remove Duplicate Items")
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(cleanupService.isCleaningUp || dataService.isSyncing)
                                
                                Button {
                                    Task {
                                        do {
                                            try await cleanupService.mergeDuplicateCategories()
                                        } catch {
                                            print("[SettingsView] ❌ Merge error: \(error)")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.triangle.merge")
                                            .font(.body)
                                        Text("Merge Duplicate Categories")
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.green)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(cleanupService.isCleaningUp || dataService.isSyncing)
                                
                                Button {
                                    Task {
                                        do {
                                            try await cleanupService.cleanupEmptyCategories()
                                        } catch {
                                            print("[SettingsView] ❌ Cleanup categories error: \(error)")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.body)
                                        Text("Clean Empty Categories")
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.purple)
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(cleanupService.isCleaningUp || dataService.isSyncing)
                                
                                Button {
                                    showingCleanupConfirmation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.body)
                                        Text("Reset CloudKit Sync")
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.orange)
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(cleanupService.isCleaningUp || dataService.isSyncing)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)
                    }
                }

                
                // Lien vers la gestion des sauvegardes
                // Button {
                //     showingBackupManagement = true
                // } label: {
                //     Text("Manual Backup")
                //         .font(.caption)
                //         .foregroundColor(.secondary)
                // }
                // .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .alert("Reset CloudKit Sync", isPresented: $showingCleanupConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        do {
                            try await cleanupService.cleanupCloudKitAndResync()
                        } catch {
                            print("[SettingsView] ❌ Cleanup error: \(error)")
                        }
                    }
                }
            } message: {
                Text("This will delete all data from CloudKit and resync from your local iPhone data. Your local data will NOT be deleted.\n\nThis can help fix sync issues.")
            }
            // .sheet(isPresented: $showingBackupManagement) {
            //     BackupManagementView(onOperationComplete: {
            //         showingBackupManagement = false
            //     })
            //         .presentationDetents([.fraction(0.5)])
            // }
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
    @State private var hapticTrigger: Int = 0
    
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
                hapticTrigger += 1
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(.green))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .cornerRadius(12)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }
}


#Preview {
    SettingsView()
}
