import SwiftUI

// MARK: - MoveToCategoryMenu
struct MoveToCategoryMenu: View {
    // MARK: - Properties
    var selectedItems: Set<UUID>
    var availableCategories: [String]
    var currentCategory: String?
    
    // MARK: - Actions
    let onMoveToCategory: (String) -> Void
    let onHaptic: () -> Void
    
    var body: some View {
        Menu {
            ForEach(availableCategories.reversed(), id: \.self) { category in
                Button {
                    onHaptic()
                    onMoveToCategory(category)
                } label: {
                    if category == currentCategory {
                        Label(category.capitalized, systemImage: "folder")
                    } else {
                        Label(category.capitalized, systemImage: "folder")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(selectedItems.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Image(systemName: "folder")
                    .font(.system(size: 19))
                    .foregroundColor(.primary)
            }
            .frame(height: 48)
            .frame(minWidth: 48)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .menuStyle(.button)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        ))
    }
}
