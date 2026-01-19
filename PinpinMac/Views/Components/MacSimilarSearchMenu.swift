//
//  MacSimilarSearchMenu.swift
//  PinpinMac
//
//  Menu contextuel pour la recherche similaire (macOS)
//

import SwiftUI

struct MacSimilarSearchMenu: View {
    let item: ContentItem
    
    // Liste des sites hardcodée pour la version Mac (équivalent à SearchSite.defaultSites)
    private let sites: [(name: String, query: String?, icon: String)] = [
        ("All", nil, "globe"),
        ("Amazon", "amazon", "shippingbox.fill"),
        ("Leboncoin", "leboncoin.fr", "tag"),
        ("eBay", "ebay.com", "chair"),
        ("Etsy", "etsy", "paintpalette"),
        ("Selency", "selency.fr", "lamp.desk"),
        ("AutoScout24", "autoscout24.com", "car"),
        ("Vestiaire Collective", "vestiairecollective.com", "bag"),
        ("Temu", "temu.com", "cart"),
        ("AliExpress", "aliexpress.com", "shippingbox"),
        ("Shein", "shein.com", "sparkles")
    ]
    
    private var canSearchSimilar: Bool {
        item.imageData != nil || (item.thumbnailUrl != nil && !item.thumbnailUrl!.isEmpty && !item.thumbnailUrl!.hasPrefix("images/") && !item.thumbnailUrl!.hasPrefix("file://"))
    }
    
    var body: some View {
        if canSearchSimilar {
            Menu {
                ForEach(sites, id: \.name) { site in
                    Button {
                        // Utilise le service partagé (qui est maintenant cross-platform)
                        SimilarSearchService.searchSimilarProducts(for: item, query: site.query)
                    } label: {
                        Label(site.name, systemImage: site.icon)
                    }
                }
            } label: {
                Label("Search Similar", systemImage: "binoculars")
            }
        }
    }
}
