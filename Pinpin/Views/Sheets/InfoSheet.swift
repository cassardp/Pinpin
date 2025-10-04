//
//  InfoSheet.swift
//  Pinpin
//
//  Sheet d'informations sur l'application
//

import SwiftUI

struct InfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Récupérer la version de l'app depuis le bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Text("Version \(appVersion)")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    InfoSheet()
}
