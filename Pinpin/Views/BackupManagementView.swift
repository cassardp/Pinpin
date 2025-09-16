//
//  BackupManagementView.swift
//  Pinpin
//
//  Vue dédiée à la gestion des sauvegardes (import/export)
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingImporter: Bool = false
    @State private var exportURL: URL? = nil
    @State private var alertMessage: String? = nil
    
    let onOperationComplete: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 0)
            // Boutons carrés pour import/export
            HStack(spacing: 30) {
                // Bouton Export
                Button {
                    do {
                        let url = try BackupService.shared.exportBackupZip()
                        exportURL = url
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    } catch {
                        alertMessage = "Export failed: \(error.localizedDescription)"
                    }
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 40))
                            .foregroundColor(.primary)
                        
                        Text("Export")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bouton Import
                Button {
                    showingImporter = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 40))
                            .foregroundColor(.primary)
                        
                        Text("Import")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 40)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [UTType.folder, UTType.package], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        try BackupService.shared.importBackup(from: url)
                        // Fermer les sheets immédiatement après import réussi
                        DispatchQueue.main.async {
                            onOperationComplete?() // Fermer settings immédiatement
                            dismiss() // Fermer backup management en même temps
                        }
                    } catch {
                        alertMessage = "Import failed: \(error.localizedDescription)"
                    }
                }
            case .failure(let error):
                alertMessage = "Import failed: \(error.localizedDescription)"
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: { exportURL != nil },
            set: { isPresented in
                if !isPresented {
                    exportURL = nil
                    // Fermer les sheets après partage
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onOperationComplete?() // Fermer settings d'abord
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss() // Puis fermer backup management
                        }
                    }
                }
            }
        )) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Backup", isPresented: .init(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

#Preview {
    BackupManagementView(onOperationComplete: nil)
}
