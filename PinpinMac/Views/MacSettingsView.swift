//
//  MacSettingsView.swift
//  PinpinMac
//
//  Vue des paramètres pour macOS (placeholder)
//

import SwiftUI

struct MacSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 40)
            
            Text("Settings will be available in a future update")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .frame(width: 400, height: 300)
    }
}
