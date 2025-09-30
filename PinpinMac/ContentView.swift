//
//  ContentView.swift
//  PinpinMac
//
//  Interface minimale pour visualiser la synchronisation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentItem.createdAt, order: .reverse) private var items: [ContentItem]
    @Query private var categories: [Category]

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Pinpin Mac")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Synchronisation CloudKit active")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            Divider()
                .padding(.horizontal)
            
            // Stats
            HStack(spacing: 40) {
                StatCard(
                    title: "Items",
                    count: items.count,
                    icon: "pin.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Catégories",
                    count: categories.count,
                    icon: "folder.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            // Info
            VStack(spacing: 12) {
                InfoRow(
                    icon: "iphone",
                    text: "Partagez du contenu depuis Safari sur Mac"
                )
                
                InfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Les données se synchronisent automatiquement avec votre iPhone"
                )
                
                InfoRow(
                    icon: "checkmark.circle.fill",
                    text: "Aucune configuration supplémentaire nécessaire"
                )
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            
            Spacer()
            
            // Footer
            Text("Utilisez le menu Partage dans Safari pour ajouter du contenu")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120, height: 120)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ContentItem.self, Category.self], inMemory: true)
}
