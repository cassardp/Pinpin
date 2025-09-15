import SwiftUI

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showSettings: Bool
    @Binding var isMenuOpen: Bool
    @FocusState private var isSearchFocused: Bool

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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.async { isSearchFocused = true }
                    }
            } else {
                controlsRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, bottomPadding)
        .opacity(isMenuOpen ? 0 : 1)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showSearchBar)
        .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
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



    // MARK: - SearchBar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)

            ZStack(alignment: .leading) {
                if searchQuery.isEmpty {
                    Text("Search your pins...")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                TextField("", text: $searchQuery)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
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
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.black.opacity(0.4))
                )
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .fill(.black.opacity(0.4))
                            )
                    )
            }

            // Centre : Search
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showSearchBar = true
                }
                DispatchQueue.main.async { isSearchFocused = true }
            }) {
                if searchQuery.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("Search")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.black.opacity(0.4))
                            )
                    )
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text(searchQuery)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) { searchQuery = "" }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black)
                    )
                }
            }

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
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        } else {
                            HStack(spacing: 4) {
                                Text("\(selectedItems.count)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 44)
                .frame(minWidth: 44)
                .padding(.horizontal, isSelectionMode ? 8 : 0)
                .background(
                    Group {
                        if isSelectionMode && !selectedItems.isEmpty {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.red)
                        } else {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(.black.opacity(0.4))
                                )
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
        }
    }
}
