//
//  MasonryGrid.swift
//  Neeed2
//
//  Masonry layout for content items
//

import SwiftUI

struct MasonryGrid<Content: View, T: Identifiable>: View {
    let items: [T]
    let columns: Int
    let spacing: CGFloat
    let content: (T) -> Content
    
    init(
        items: [T],
        columns: Int,
        spacing: CGFloat = 2,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(itemsForColumn(columnIndex)) { item in
                        content(item)
                    }
                }
            }
        }
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [T] {
        return items.enumerated().compactMap { index, item in
            return index % columns == columnIndex ? item : nil
        }
    }
}
