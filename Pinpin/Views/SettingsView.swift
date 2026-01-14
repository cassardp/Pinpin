//
//  SettingsView.swift
//  Pinpin
//
//  Vue des paramètres de l'application
//

import SwiftUI
import CloudKit

struct SettingsView: View {
    @Bindable private var userPreferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                
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

                }
                .padding(.horizontal, 20)

                // Ligne de séparation
                Divider()
                    .background(Color.gray.opacity(0.1))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                
                CloudKitPurgeSection()
                    .padding(.bottom, 20)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    // MARK: - Helper Methods
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

// MARK: - CloudKit Purge Section
struct CloudKitPurgeSection: View {
    @State private var showConfirmation = false
    @State private var isPurging = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Button(action: {
            showConfirmation = true
        }) {
            HStack {
                Text("Zero Cloud")
                    .foregroundColor(.red)
                Spacer()
                if isPurging {
                    ProgressView()
                } else {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .disabled(isPurging)
        .alert("Purge iCloud Data?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                purgeCloudKit()
            }
        } message: {
            Text("This will permanently delete all data in the iCloud Private Database for this app. Local data will not be affected.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func purgeCloudKit() {
        isPurging = true
        
        // Use the container logic from AppConstants
        let container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        let database = container.privateCloudDatabase
        
        database.fetchAllRecordZones { zones, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch zones: \(error.localizedDescription)"
                    self.showingError = true
                    self.isPurging = false
                }
                return
            }
            
            guard let zones = zones, !zones.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "No zones found to delete."
                    self.showingError = true // Or just a success message
                    self.isPurging = false
                }
                return
            }
            
            let zoneIDs = zones.map { $0.zoneID }
            let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: zoneIDs)
            
            operation.modifyRecordZonesResultBlock = { result in
                DispatchQueue.main.async {
                    self.isPurging = false
                    switch result {
                    case .success:
                        print("Successfully purged CloudKit zones.")
                    case .failure(let error):
                        self.errorMessage = "Failed to purge zones: \(error.localizedDescription)"
                        self.showingError = true
                    }
                }
            }
            
            database.add(operation)
        }
    }
}


#Preview {
    SettingsView()
}
