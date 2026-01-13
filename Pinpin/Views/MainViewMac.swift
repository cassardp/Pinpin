#if os(macOS)
import SwiftUI
import CoreData

struct MainViewMac: View {
    @StateObject private var contentService = ContentServiceCoreData()
    @StateObject private var sharedContentService: SharedContentService
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var coreDataService = CoreDataService.shared
    
    @State private var selectedCategory: Category?
    @State private var selectedContentDetails: ContentItem?
    @State private var searchQuery: String = ""
    @State private var columnCount: Int = 4
    
    init() {
        let contentService = ContentServiceCoreData()
        self._contentService = StateObject(wrappedValue: contentService)
        self._sharedContentService = StateObject(wrappedValue: SharedContentService(contentService: contentService))
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)],
        animation: .default)
    private var allContentItems: FetchedResults<ContentItem>
    
    var filteredItems: [ContentItem] {
        let items = Array(allContentItems)
        let categoryFiltered: [ContentItem]
        
        if let category = selectedCategory {
            categoryFiltered = items.filter { $0.category == category }
        } else {
             categoryFiltered = items
        }
        
        if searchQuery.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { item in
                 let title = item.title?.lowercased() ?? ""
                 return title.contains(searchQuery.lowercased())
            }
        }
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
                Text("All Items")
                    .tag(Optional<Category>.none)
                
                Section("Categories") {
                    ForEach(categories) { category in
                        HStack {
                            Image(systemName: category.iconName ?? "folder")
                                .foregroundColor(Color(hex: category.colorHex ?? "#000000"))
                            Text(category.name ?? "Unknown")
                        }
                        .tag(Optional(category))
                    }
                }
            }
            .navigationTitle("Pinpin")
        } detail: {
            ScrollView {
                PinterestLayoutWrapper(numberOfColumns: columnCount, itemSpacing: 10) {
                    ForEach(filteredItems, id: \.self) { item in
                        ContentItemCardMac(
                            item: item,
                            cornerRadius: 12,
                            numberOfColumns: columnCount,
                            isSelectionMode: false,
                            onSelectionTap: nil
                        )
                        .onTapGesture {
                            // Open detail or URL
                             if let urlString = item.url, let url = URL(string: urlString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                contentService.deleteContentItem(item)
                            }
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $searchQuery)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Slider(value: Binding(get: { Double(columnCount) }, set: { columnCount = Int($0) }), in: 2...6, step: 1) {
                        Text("Columns")
                    }
                    .frame(width: 100)
                }
            }
        }
        .onAppear {
            contentService.loadContentItems()
        }
    }
}
#endif
