import SwiftUI

struct CategoryListRow: View {
    let isSelected: Bool
    let title: String
    let isEmpty: Bool
    let action: () -> Void
    let onRename: (() -> Void)?
    let onDelete: (() -> Void)?
    let canDelete: Bool
    @State private var hapticTrigger: Int = 0
    
    init(
        isSelected: Bool,
        title: String,
        isEmpty: Bool,
        action: @escaping () -> Void,
        onRename: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        canDelete: Bool = true
    ) {
        self.isSelected = isSelected
        self.title = title
        self.isEmpty = isEmpty
        self.action = action
        self.onRename = onRename
        self.onDelete = onDelete
        self.canDelete = canDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
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
            .padding(.vertical, -6)
            
            Spacer()
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onTapGesture {
            hapticTrigger += 1
            withAnimation(.easeInOut) {
                action()
            }
        }
        .contextMenu {
            if let onRename {
                Button {
                    onRename()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
            
            if let onDelete, canDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .opacity(isEmpty ? 0.6 : 1.0)
    }
}
