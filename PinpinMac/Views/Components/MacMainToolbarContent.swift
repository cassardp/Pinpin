//
//  MacMainToolbarContent.swift
//  PinpinMac
//
//  Contenu des toolbars pour MacMainView
//

import SwiftUI

// MARK: - Column Control

struct ColumnControlGroup: View {
    let numberOfColumns: Int
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        ControlGroup {
            Button(action: onDecrease) {
                Image(systemName: "minus")
            }
            .disabled(numberOfColumns <= AppConstants.minColumns)

            Button(action: onIncrease) {
                Image(systemName: "plus")
            }
            .disabled(numberOfColumns >= AppConstants.maxColumns)
        }
        .controlGroupStyle(.navigation)
    }
}

// MARK: - Normal Mode Toolbar

struct MacNormalModeToolbar: ToolbarContent {
    let numberOfColumns: Int
    let onColumnDecrease: () -> Void
    let onColumnIncrease: () -> Void
    let onSelect: () -> Void
    let onAddNote: () -> Void

    var body: some ToolbarContent {
        ToolbarItem {
            ColumnControlGroup(
                numberOfColumns: numberOfColumns,
                onDecrease: onColumnDecrease,
                onIncrease: onColumnIncrease
            )
        }

        ToolbarSpacer(.flexible)

        ToolbarItem {
            Button(action: onAddNote) {
                Label("Add Note", systemImage: "textformat")
            }
        }

        ToolbarSpacer(.fixed)

        ToolbarItem {
            Button(action: onSelect) {
                Label("Select", systemImage: "checkmark")
            }
        }

        ToolbarSpacer(.flexible)
    }
}

// MARK: - Selection Mode Toolbar

struct MacSelectionModeToolbar: ToolbarContent {
    let numberOfColumns: Int
    let hasSelection: Bool
    let selectedCount: Int
    let categoryNames: [String]

    let onColumnDecrease: () -> Void
    let onColumnIncrease: () -> Void
    let onSelectAll: () -> Void
    let onMoveToCategory: (String) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    var body: some ToolbarContent {
        ToolbarItem {
            ColumnControlGroup(
                numberOfColumns: numberOfColumns,
                onDecrease: onColumnDecrease,
                onIncrease: onColumnIncrease
            )
        }

        ToolbarSpacer(.flexible)

        if hasSelection {
            selectionActions
        } else {
            noSelectionActions
        }

        ToolbarSpacer(.flexible)
    }

    @ToolbarContentBuilder
    private var selectionActions: some ToolbarContent {
        // Move with count
        ToolbarItem {
            Menu {
                ForEach(categoryNames, id: \.self) { categoryName in
                    Button {
                        onMoveToCategory(categoryName)
                    } label: {
                        Label(categoryName, systemImage: "folder")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                    Text("\(selectedCount)")
                }
            }
            .menuIndicator(.hidden)
        }

        ToolbarSpacer(.fixed)

        // Delete with count
        ToolbarItem {
            Button(action: onDelete) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("\(selectedCount)")
                }
                .foregroundStyle(.red)
            }
        }

        ToolbarSpacer(.fixed)

        // Close
        ToolbarItem {
            Button(action: onClose) {
                Label("Close", systemImage: "xmark")
            }
        }
    }

    @ToolbarContentBuilder
    private var noSelectionActions: some ToolbarContent {
        // Select All
        ToolbarItem {
            Button(action: onSelectAll) {
                Text("Select All")
            }
        }

        ToolbarSpacer(.fixed)

        // Close
        ToolbarItem {
            Button(action: onClose) {
                Label("Close", systemImage: "xmark")
            }
        }
    }
}
