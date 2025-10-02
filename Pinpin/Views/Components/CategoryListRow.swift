import SwiftUI

struct CategoryListRow: View {
    let isSelected: Bool
    let title: String
    let isEmpty: Bool
    let isEditing: Bool
    let action: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let canDelete: Bool
    @State private var hapticTrigger: Int = 0
    
    init(
        isSelected: Bool,
        title: String,
        isEmpty: Bool,
        isEditing: Bool = false,
        action: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        canDelete: Bool = true
    ) {
        self.isSelected = isSelected
        self.title = title
        self.isEmpty = isEmpty
        self.isEditing = isEditing
        self.action = action
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.canDelete = canDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                if isSelected {
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
            .padding(.vertical, -4)
            
            Spacer()
            
            if isEditing {
                HStack(spacing: 16) {
                    if let onDelete, canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onTapGesture {
            hapticTrigger += 1
            withAnimation(.easeInOut) {
                if isEditing, let onEdit {
                    onEdit()
                } else {
                    action()
                }
            }
        }
        .opacity(isEmpty ? 0.6 : 1.0)
    }
}
