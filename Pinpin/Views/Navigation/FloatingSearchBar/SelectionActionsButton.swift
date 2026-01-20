import SwiftUI

// MARK: - SelectionActionsButton
struct SelectionActionsButton: View {
    // MARK: - Bindings
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showDeleteConfirmation: Bool
    
    // MARK: - Properties
    var scrollProgress: CGFloat
    
    // MARK: - Actions
    let onSelectAll: () -> Void
    let onHaptic: () -> Void
    
    var body: some View {
        Button(action: {
            onHaptic()
            
            if isSelectionMode {
                if selectedItems.isEmpty {
                    onSelectAll()
                } else {
                    showDeleteConfirmation = true
                }
            } else {
                withAnimation(.smooth(duration: 0.3)) {
                    isSelectionMode = true
                }
            }
        }) {
            Group {
                if isSelectionMode {
                    if selectedItems.isEmpty {
                        Text("All")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        HStack(spacing: 4) {
                            Text("\(selectedItems.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "trash")
                                .font(.system(size: 19))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 48)
            .frame(minWidth: 48)
            .padding(.horizontal, isSelectionMode ? 8 : 0)
            .background(
                Group {
                    if isSelectionMode && !selectedItems.isEmpty {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.red)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            )
        }
        .opacity(isSelectionMode ? 1 : (scrollProgress > 0.5 ? 0 : CGFloat(1 - (scrollProgress * 2))))
    }
}
