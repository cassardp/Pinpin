//
//  MacSelectionManager.swift
//  PinpinMac
//
//  Gère la sélection multiple d'items avec @Observable
//

import SwiftUI

@Observable
@MainActor
final class MacSelectionManager {
    var isSelectionMode: Bool = false
    var selectedItems: Set<UUID> = []
    
    // MARK: - Selection Actions
    
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedItems.removeAll()
        }
    }
    
    func toggleSelection(for itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
    
    func selectAll(items: [UUID]) {
        selectedItems = Set(items)
    }
    
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    func isSelected(_ itemId: UUID) -> Bool {
        selectedItems.contains(itemId)
    }
    
    // MARK: - Computed
    
    var selectedCount: Int {
        selectedItems.count
    }
    
    var hasSelection: Bool {
        !selectedItems.isEmpty
    }
}
