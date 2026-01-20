//
//  MacSettingsMenu.swift
//  PinpinMac
//
//  Menu "⚙️" pour Settings et About
//

import SwiftUI

struct MacSettingsMenu: View {
    let onSettings: () -> Void
    let onAbout: () -> Void
    
    var body: some View {
        Menu {
            Button {
                onSettings()
            } label: {
                Label("Settings", systemImage: "gear")
            }
            
            Divider()
            
            Button {
                onAbout()
            } label: {
                Label("About", systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "gear")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 24, height: 24)
    }
}
