//
//  Neeed2App.swift
//  Neeed2
//
//  Created by Patrice on 12/06/2025.
//

import SwiftUI
import CoreData

@main
struct PinpinApp: App {
    @StateObject private var coreDataService = CoreDataService.shared
    
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MainViewMac()
                .environment(\.managedObjectContext, coreDataService.context)
                .font(.system(.body, design: .rounded))
                .onAppear {
                    coreDataService.createDefaultCategoriesIfNeeded()
                }
            #else
            MainView()
                .environment(\.managedObjectContext, coreDataService.context)
                .font(.system(.body, design: .rounded))
                .onAppear {
                    coreDataService.createDefaultCategoriesIfNeeded()
                }
            #endif
        }
    }
}
