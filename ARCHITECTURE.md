# Architecture Pinpin

## 📁 Structure du Projet

```
Pinpin/
├── Shared/                          # Code partagé entre App et Extension
│   ├── AppConstants.swift          # Constantes centralisées
│   └── Services/
│       └── ImageOptimizationService.swift
│
├── Models/                          # Modèles SwiftData
│   ├── ContentItem.swift
│   └── Category.swift
│
├── Services/                        # Services métier
│   ├── DataService.swift           # Service principal SwiftData
│   ├── ContentFilterService.swift  # Filtrage et recherche
│   ├── CategoryOrderService.swift  # Ordre des catégories
│   ├── NotificationContentService.swift  # Communication App/Extension
│   ├── ErrorHandler.swift          # Gestion des erreurs
│   ├── BackupService.swift
│   ├── ImageUploadService.swift
│   ├── ThemeManager.swift
│   └── UserPreferences.swift
│
├── ViewModels/                      # ViewModels MVVM
│   └── MainViewModel.swift         # ViewModel de MainView
│
├── Views/                           # Vues SwiftUI
│   ├── MainView.swift
│   ├── FilterMenuView.swift
│   ├── FloatingSearchBar.swift
│   ├── Components/
│   ├── ContentViews/
│   └── Sheets/
│
└── PinpinShareExtension/            # Extension de partage
    ├── ShareViewController.swift
    ├── OCRService.swift
    └── ...
```

## 🏗️ Principes d'Architecture

### 1. **Séparation des Responsabilités**

- **Models** : Définition des données (SwiftData)
- **Services** : Logique métier et accès aux données
- **ViewModels** : Logique de présentation et état
- **Views** : Interface utilisateur uniquement

### 2. **Code Partagé**

Le dossier `Shared/` contient le code utilisé par :
- ✅ L'application principale
- ✅ L'extension de partage

**Important** : Cocher les deux targets dans Target Membership pour ces fichiers.

### 3. **Constantes Centralisées**

Toutes les constantes sont dans `AppConstants.swift` :
- IDs App Group et CloudKit
- Paramètres d'optimisation d'images
- Noms de fichiers
- Valeurs par défaut

**Avantages** :
- ✅ Pas de duplication
- ✅ Facile à maintenir
- ✅ Une seule source de vérité

### 4. **Services Spécialisés**

Chaque service a une responsabilité unique :

| Service | Responsabilité |
|---------|---------------|
| `DataService` | CRUD SwiftData + iCloud |
| `ContentFilterService` | Filtrage et recherche |
| `CategoryOrderService` | Ordre personnalisé des catégories |
| `ImageOptimizationService` | Compression et redimensionnement |
| `ErrorHandler` | Gestion centralisée des erreurs |
| `NotificationContentService` | Communication App/Extension |

### 5. **MVVM Pattern**

```swift
// ViewModel gère la logique
@MainActor
final class MainViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    
    func filteredItems(from items: [ContentItem]) -> [ContentItem] {
        // Logique de filtrage
    }
}

// View affiche uniquement
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        // UI uniquement
    }
}
```

## 🔄 Flux de Données

### Partage depuis une autre app

```
App externe
    ↓
ShareViewController (Extension)
    ↓
ImageOptimizationService.optimize()
    ↓
NotificationContentService.saveSharedContent()
    ↓ (Fichier JSON dans App Group)
MainView.onAppear()
    ↓
NotificationContentService.processPendingSharedContents()
    ↓
DataService.saveContentItemWithImageData()
    ↓
SwiftData + iCloud Sync
```

### Recherche et Filtrage

```
MainView
    ↓
MainViewModel.filteredItems()
    ↓
ContentFilterService.filter()
    ↓
Items filtrés affichés
```

## 🎯 Bonnes Pratiques

### ✅ À FAIRE

1. **Utiliser les constantes** : `AppConstants.groupID` au lieu de hardcoder
2. **Utiliser les services** : `ImageOptimizationService.shared.optimize()` au lieu de dupliquer
3. **Gérer les erreurs** : `ErrorHandler.shared.handle(error)` au lieu de `print()`
4. **Séparer la logique** : ViewModel pour la logique, View pour l'UI
5. **Tester les services** : Les services sont facilement testables

### ❌ À ÉVITER

1. ❌ Dupliquer les constantes dans plusieurs fichiers
2. ❌ Mettre la logique métier dans les Views
3. ❌ Ignorer les erreurs silencieusement
4. ❌ Créer des fichiers de 500+ lignes
5. ❌ Dupliquer le code entre App et Extension

## 🧪 Tests

### Services à tester en priorité

1. `ContentFilterService` - Logique de filtrage critique
2. `ImageOptimizationService` - Compression d'images
3. `CategoryOrderService` - Gestion de l'ordre
4. `MainViewModel` - Logique de présentation

### Exemple de test

```swift
final class ContentFilterServiceTests: XCTestCase {
    func testFilterByCategory() {
        let service = ContentFilterService.shared
        let items = [/* test items */]
        
        let filtered = service.filter(
            items: items,
            category: "Tech",
            query: ""
        )
        
        XCTAssertEqual(filtered.count, 2)
    }
}
```

## 📊 Métriques de Qualité

### Avant Refactoring
- 📄 MainView.swift : **582 lignes**
- 📄 DataService.swift : **635 lignes**
- 🔄 Code dupliqué : **~300 lignes**
- ⚠️ Constantes dupliquées : **15+**

### Après Refactoring
- 📄 MainView.swift : **~400 lignes** (logique → ViewModel)
- 📄 DataService.swift : **~500 lignes** (nettoyage prévu Phase 3)
- 🔄 Code dupliqué : **~50 lignes**
- ✅ Constantes centralisées : **1 fichier**
- ✅ Services réutilisables : **7 services**
- ✅ ViewModels : **1 (extensible)**

## 🚀 Prochaines Étapes

### Phase 2 (En cours)
- [ ] Simplifier MainView avec MainViewModel
- [ ] Extraire composants de FloatingSearchBar

### Phase 3 (À venir)
- [ ] Séparer DataService en repositories
- [ ] ContentItemRepository
- [ ] CategoryRepository
- [ ] CloudSyncService

### Phase 4 (À venir)
- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] Documentation API

## 📝 Notes de Migration

### Pour ajouter un nouveau service partagé

1. Créer le fichier dans `Pinpin/Shared/Services/`
2. Cocher les deux targets dans Target Membership
3. Utiliser `AppConstants` pour les constantes
4. Documenter dans ce fichier

### Pour ajouter une nouvelle constante

1. Ajouter dans `AppConstants.swift`
2. Remplacer les occurrences hardcodées
3. Tester App + Extension

---

**Dernière mise à jour** : 2025-09-30
**Version** : 1.0 (Phase 1 complétée)
