//
//  SearchSite.swift
//  Pinpin
//
//  Modèle pour les sites de recherche similaire
//

import Foundation

struct SearchSite: Identifiable, Codable {
    let id: UUID
    let name: String
    let query: String?
    let iconName: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, query: String?, iconName: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.query = query
        self.iconName = iconName
        self.isEnabled = isEnabled
    }
    
    static let defaultSites: [SearchSite] = [
        SearchSite(name: "All", query: nil, iconName: "globe"),
        SearchSite(name: "Amazon", query: "amazon", iconName: "shippingbox.fill"),
        SearchSite(name: "Leboncoin", query: "leboncoin.fr", iconName: "tag"),
        SearchSite(name: "eBay", query: "ebay.com", iconName: "chair"),
        SearchSite(name: "Etsy", query: "etsy", iconName: "paintpalette"),
        SearchSite(name: "Selency", query: "selency.fr", iconName: "lamp.desk"),
        SearchSite(name: "AutoScout24", query: "autoscout24.com", iconName: "car"),
        SearchSite(name: "Vestiaire Collective", query: "vestiairecollective.com", iconName: "bag"),
        SearchSite(name: "Temu", query: "temu.com", iconName: "cart"),
        SearchSite(name: "AliExpress", query: "aliexpress.com", iconName: "shippingbox"),
        SearchSite(name: "Shein", query: "shein.com", iconName: "sparkles")
    ]
}
