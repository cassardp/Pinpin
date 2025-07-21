//
//  SettingsView.swift
//  Neeed2
//
//  Vue des paramètres de l'application
//

import SwiftUI

struct SettingsView: View {
    @Binding var isSwipingHorizontally: Bool
    @StateObject private var userPreferences = UserPreferences.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Switch pour afficher les URLs
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        

                        
                        HStack {
                            
                            VStack(alignment: .leading, spacing: 2) {
                                
                                Text("Show URLs")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text("Under each item")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $userPreferences.showURLs)
                                .labelsHidden()
                                .tint(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 400)
                }
            }
            .scrollIndicators(.hidden)
            .disabled(isSwipingHorizontally)
        }
    }
}

#Preview {
    SettingsView(isSwipingHorizontally: .constant(false))
}
