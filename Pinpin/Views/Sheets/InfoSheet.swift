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
            ScrollView {
                VStack(spacing: 24) {
                    // App Name
                    VStack(spacing: 12) {
                        Text("Pinpin")
                            .font(.system(size: 32, weight: .bold))
                    }
                    .padding(.top, 32)

                    // Description
                    VStack(spacing: 16) {
                        Text("Share anything, find everything.")
                            .font(.system(size: 17, weight: .semibold))

                        Text("Share web pages, images, and create text notes from anywhere — whether you're browsing Safari, scrolling social media, or working in any app. Everything you share is instantly available.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Version
                    Text("Version \(appVersion)")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 32)
                }
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

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    InfoSheet()
}
