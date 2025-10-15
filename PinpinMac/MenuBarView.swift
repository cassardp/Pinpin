//
//  MenuBarView.swift
//  PinpinMac
//
//  Menu Bar minimal
//

import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pinpin")
                .font(.headline)
                .padding(12)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(8)
        }
        .frame(width: 180)
    }
}
