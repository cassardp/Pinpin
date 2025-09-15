import SwiftUI

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showSettings: Bool
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
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showSearchBar)
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
                .foregroundColor(.secondary)

            TextField("Search your pins...", text: $searchQuery)
                .font(.system(size: 17))
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
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 15)
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
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
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
                            .foregroundColor(.secondary)
                        Text("Search")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
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
                            .foregroundColor(.white.opacity(0.6))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) { searchQuery = "" }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black)
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
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
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                Text("\(selectedItems.count)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.red)
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 44)
                .frame(minWidth: 44)
                .padding(.horizontal, isSelectionMode ? 8 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
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
