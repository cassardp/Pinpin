//
//  FloatingSearchBar.swift
//  Pinpin
//
//  Barre de recherche flottante moderne en bas d'écran
//

import SwiftUI
import Combine

struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @FocusState private var isSearchFocused: Bool
    
    // État pour la détection du clavier
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    var body: some View {
        VStack {
            // Zone de tap pour fermer la recherche
            if showSearchBar {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            showSearchBar = false
                            isSearchFocused = false
                        }
                    }
            } else {
                Spacer()
            }
            
            // Barre de recherche flottante
            if showSearchBar {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search your pins...", text: $searchQuery)
                        .font(.system(size: 17, weight: .regular))
                        .focused($isSearchFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .onSubmit {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                showSearchBar = false
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
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
                .padding(.horizontal, 16)
                .padding(.bottom, isKeyboardVisible ? keyboardHeight + 10 : 34)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFocused = true
                    }
                }
            } else {
                // Bouton de recherche compact ou capsule avec terme de recherche
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSearchBar = true
                    }
                }) {
                    if searchQuery.isEmpty {
                        // État normal - bouton Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("Search")
                                .font(.system(size: 16, weight: .regular))
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
                        // Capsule avec terme de recherche actif
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(searchQuery)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    searchQuery = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black)
                                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = height
                isKeyboardVisible = height > 0
            }
        }
    }
}

// Extension pour détecter la hauteur du clavier
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// MARK: - Preview
#Preview {
    FloatingSearchBar(
        searchQuery: .constant(""),
        showSearchBar: .constant(false)
    )
}
