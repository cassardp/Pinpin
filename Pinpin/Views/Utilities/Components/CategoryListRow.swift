import SwiftUI

struct CategoryListRow: View {
    let isSelected: Bool
    let title: String
    let isEmpty: Bool
    let action: () -> Void
    let onRename: (() -> Void)?
    let onDelete: (() -> Void)?
    let canDelete: Bool
    let isEditing: Bool
    @State private var hapticTrigger: Int = 0
    
    init(
        isSelected: Bool,
        title: String,
        isEmpty: Bool,
        action: @escaping () -> Void,
        onRename: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        canDelete: Bool = true,
        isEditing: Bool = false
    ) {
        self.isSelected = isSelected
        self.title = title
        self.isEmpty = isEmpty
        self.action = action
        self.onRename = onRename
        self.onDelete = onDelete
        self.canDelete = canDelete
        self.isEditing = isEditing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Bouton de suppression en mode édition (à gauche)
            if isEditing && canDelete {
                Button {
                    hapticTrigger += 1
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .padding(.trailing, 4)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            HStack(spacing: 8) {
                if isSelected && !isEditing {
                    Circle()
                        .fill(isEmpty ? Color.secondary : Color.primary)
                        .frame(width: 8, height: 8)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Text(title.count > 16 ? String(title.prefix(13)) + "..." : title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isEmpty ? .secondary : .primary)
                    .lineLimit(1)
            }
            .padding(.vertical, -6)
            
            Spacer()
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onTapGesture {
            hapticTrigger += 1
            if isEditing {
                // En mode édition, tap pour renommer
                onRename?()
            } else {
                // En mode normal, tap pour sélectionner
                withAnimation(.easeInOut) {
                    action()
                }
            }
        }
        .opacity(isEmpty ? 0.6 : 1.0)
    }
}
