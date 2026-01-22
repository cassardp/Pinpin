import SwiftUI
import UniformTypeIdentifiers

struct CategoryDropDelegate: DropDelegate {
    let item: Category
    let visibleCategories: [Category]
    @Binding var draggingItem: Category?
    let onMove: (IndexSet, Int) -> Void
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [UTType.text])
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggingItem,
              draggingItem.id != item.id,
              let fromIndex = visibleCategories.firstIndex(where: { $0.id == draggingItem.id }),
              let toIndex = visibleCategories.firstIndex(where: { $0.id == item.id })
        else { return }
        
        let destinationIndex = toIndex > fromIndex ? toIndex + 1 : toIndex
        
        // Empêcher les updates redondants si l'ordre est déjà bon (optionnel mais bien)
        // Ici on appelle le move qui va trigger l'animation
        // Note: l'animation doit être gérée par le caller ou ici avec withAnimation
        
        // On délègue le move réel
        onMove(IndexSet(integer: fromIndex), destinationIndex)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
    
    // Nécessaire pour éviter le flicker sur certains OS
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
