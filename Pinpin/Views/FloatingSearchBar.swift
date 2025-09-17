import SwiftUI

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showSettings: Bool
    var menuSwipeProgress: CGFloat
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchTransitionNS
    @State private var isAnimatingSearchOpen: Bool = false

    // Data
    var selectedContentType: String?
    var totalPinsCount: Int = 0

    // Actions
    let onSelectAll: () -> Void
    let onDeleteSelected: () -> Void

    // Insets
    var bottomPadding: CGFloat = 12

    var body: some View {
        // Seulement la barre de recherche/contrôles pour safeAreaInset
        ZStack {
            if showSearchBar {
                searchBar
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .bottom)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                    .onAppear {
                        // Delay focus slightly so the keyboard appears after the expansion animation
                        let delay = 0.18
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            isSearchFocused = true
                            isAnimatingSearchOpen = false
                        }
                    }
            } else {
                controlsRow
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .bottom)).combined(with: .move(edge: .bottom))
                    ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, bottomPadding)
        .opacity(1 - menuSwipeProgress)
        .animation(.spring(response: 0.36, dampingFraction: 0.86, blendDuration: 0.08), value: showSearchBar)
        .animation(.spring(response: 0.36, dampingFraction: 0.86, blendDuration: 0.08), value: isAnimatingSearchOpen)
    }
    
    // MARK: - Overlay séparé pour MainView
    func overlayView() -> some View {
        Group {
            if showSearchBar {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { dismissSearch() }
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Placeholder
    private var placeholderText: String {
        if let selectedType = selectedContentType {
            // Catégorie spécifique sélectionnée
            let categoryName = selectedType.capitalized
            return "Search in \(categoryName)..."
        } else {
            // Catégorie "All"
            if totalPinsCount > 0 {
                return "Search in your \(totalPinsCount) pin\(totalPinsCount > 1 ? "s" : "")..."
            } else {
                return "Search in your pins..."
            }
        }
    }

    // MARK: - SearchBar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)

            ZStack(alignment: .leading) {
                if searchQuery.isEmpty {
                    Text(placeholderText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.primary.opacity(0.5))
                }
                TextField("", text: $searchQuery)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
            }
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .onSubmit { dismissSearch() }

            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.thinMaterial)
                .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
        )
        .padding(.bottom, 12)
    }

    // MARK: - Row compacte
    private var controlsRow: some View {
        HStack {
            Spacer()

            // Gauche : Settings / Cancel
            Button(action: {
                if isSelectionMode {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSelectionMode = false
                        selectedItems.removeAll()
                    }
                } else {
                    showSettings = true
                }
            }) {
                Image(systemName: isSelectionMode ? "xmark" : "slider.vertical.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.thinMaterial)
                    )
            }

            // Centre : Search
            Button(action: {
                isAnimatingSearchOpen = true
                withAnimation(.spring(response: 0.36, dampingFraction: 0.86, blendDuration: 0.08)) {
                    showSearchBar = true
                }
                // Focus will be set in searchBar.onAppear with a slight delay
            }) {
                if searchQuery.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Search")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .contentTransition(.opacity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.thinMaterial)
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.systemBackground))
                        Text(searchQuery)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(.systemBackground))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemBackground))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86, blendDuration: 0.08)) {
                                    searchQuery = ""
                                }
                            }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .contentTransition(.opacity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(.label))
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86, blendDuration: 0.08), value: searchQuery)

            // Droite : Selection / Delete
            Button(action: {
                if isSelectionMode {
                    if selectedItems.isEmpty {
                        onSelectAll()
                    } else {
                        onDeleteSelected()
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .padding(.bottom, 1)
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
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.red)
                        } else {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.thinMaterial)
                        }
                    }
                )
            }

            Spacer()
        }
    }

    // MARK: - Helper
    private func dismissSearch() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showSearchBar = false
            isSearchFocused = false
            isAnimatingSearchOpen = false
        }
    }
}

