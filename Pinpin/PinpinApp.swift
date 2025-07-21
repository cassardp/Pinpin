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
            MainView()
                .environment(\.managedObjectContext, coreDataService.context)
                .font(.system(.body, design: .rounded))
        }
    }
}
