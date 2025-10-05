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
                        Text("Capture anything, find everything.")
                            .font(.system(size: 17, weight: .semibold))

                        Text("Save web pages, images, and create text notes from anywhere — whether you're browsing Safari, scrolling social media, or working in any app. Everything you capture is instantly available.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "square.and.arrow.up", text: "Universal capture: Share from any app or website with one tap")
                            FeatureRow(icon: "doc.text.viewfinder", text: "Smart text recognition: Images are automatically processed with OCR")
                            FeatureRow(icon: "folder.fill", text: "Organize your way: Use categories to keep everything structured")
                            FeatureRow(icon: "note.text", text: "Create on the go: Capture content or write quick text notes")
                            FeatureRow(icon: "magnifyingglass", text: "Search instantly: Find anything across all your saved content")
                            FeatureRow(icon: "binoculars", text: "Search similar: Discover related content with intelligent similarity search")
                            FeatureRow(icon: "icloud.fill", text: "iCloud sync: Seamless sync across iPhone, iPad, and Mac")
                            FeatureRow(icon: "lock.shield.fill", text: "Privacy-first: All your data stays yours, encrypted in your iCloud")
                        }
                        .padding(.top, 8)
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
