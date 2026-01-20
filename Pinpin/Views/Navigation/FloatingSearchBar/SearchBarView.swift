import SwiftUI

// MARK: - SearchBarView
struct SearchBarView: View {
    // MARK: - Bindings
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @FocusState.Binding var isSearchFocused: Bool
    
    // MARK: - Properties
    var selectedContentType: String?
    var showCapsules: Bool
    var showCloseButton: Bool
    var searchTransitionNS: Namespace.ID
    
    // MARK: - Actions
    let onDismiss: () -> Void
    let onHaptic: () -> Void
    
    // MARK: - Constants
    private let searchTransitionAnimation = Animation.smooth(duration: 0.35)
    
    // MARK: - Computed Properties
    private var placeholderText: String {
        if let selectedType = selectedContentType {
            return "Search in \(selectedType.capitalized)..."
        }
        return "Search..."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Capsules de recherche prédéfinies (sans padding horizontal)
            if showCapsules {
                PredefinedSearchView(
                    searchQuery: $searchQuery,
                    selectedContentType: selectedContentType,
                    onSearchSelected: onDismiss
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity).combined(with: .move(edge: .top)),
                        removal: .scale(scale: 0.95, anchor: .top).combined(with: .opacity)
                    )
                )
            }
            
            // Barre de recherche principale (avec padding horizontal)
            HStack(spacing: 8) {
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary.opacity(0.4))
                        .matchedGeometryEffect(id: "searchIcon", in: searchTransitionNS)
                    
                    ZStack(alignment: .leading) {
                        if searchQuery.isEmpty {
                            Text(placeholderText)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary.opacity(0.4))
                                .opacity(showSearchBar ? 1 : 0)
                                .animation(searchTransitionAnimation.delay(0.1), value: showSearchBar)
                        }
                        TextField("", text: $searchQuery)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                            .opacity(showSearchBar ? 1 : 0)
                            .animation(searchTransitionAnimation.delay(0.1), value: showSearchBar)
                    }
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .onSubmit { onDismiss() }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            onHaptic()
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 48)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                )
                
                // Bouton xmark pour fermer le clavier
                if showCloseButton {
                    Button {
                        onHaptic()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(.bottom, 12)
            .padding(.horizontal, 12) // Padding pour la barre de recherche seulement
        }
    }
}
