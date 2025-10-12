# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

Build iOS app:
```bash
xcodebuild -scheme Pinpin -quiet
```

Build macOS app:
```bash
xcodebuild -scheme PinpinMac -quiet
```

Build all targets:
```bash
xcodebuild -alltargets -quiet
```

## Architecture Overview

**Pinpin** est une app iOS/macOS de type Pinterest pour sauvegarder et organiser du contenu (URLs, images, texte). L'architecture suit le pattern Repository + MVVM avec SwiftData pour la persistence.

### Core Architecture Layers

1. **Models** (`Pinpin/Shared/Models/`)
   - `ContentItem`: Élément de contenu principal (@Model SwiftData)
   - `Category`: Catégorie pour organiser le contenu (@Model SwiftData)
   - Relations: `Category` -> `[ContentItem]` (one-to-many avec deleteRule: .nullify)

2. **Repositories** (`Pinpin/Repositories/`)
   - `ContentItemRepository`: CRUD et queries pour ContentItem
   - `CategoryRepository`: CRUD et queries pour Category
   - Pattern: Tous les repositories prennent un `ModelContext` en init
   - Méthodes upsert() pour merge par ID (critical pour backup/restore et CloudKit sync)

3. **Services** (`Pinpin/Services/`)
   - `DataService`: Service principal @MainActor, singleton, expose repositories via API haut niveau
   - `BackupService`: Export/import JSON + images embarquées (format dossier avec items.json + images/)
   - `ImageOptimizationService`: Compression images pour SwiftData (max 1MB)
   - `OCRService`: Extraction texte des images (Vision framework)
   - `MaintenanceService`: Cleanup et migrations

4. **ViewModels** (`Pinpin/ViewModels/`)
   - `MainViewModel`: @ObservableObject pour MainView (filtrage, recherche, sélection, pagination)
   - ⚠️ Utilise encore @ObservableObject/@Published (legacy) - à migrer vers @Observable

5. **Views** (`Pinpin/Views/`)
   - `MainView`: Vue principale avec grid Pinterest
   - `FloatingSearchBar`: Barre de recherche avec animation de scroll
   - `ContentCardView`: Card individuelle avec lazy loading
   - Layout: `PinterestLayout` custom pour grille type masonry

### Share Extension Architecture

**Important**: L'app a 2 share extensions (iOS + macOS) qui partagent le container SwiftData via App Group.

- Fichiers: `PinpinShareExtension/ShareViewController.swift`, `PinpinMacShareExtension/ShareViewController.swift`
- Pattern: LinkPresentation pour fetch métadonnées + ImageProvider -> OCR automatique -> Save via repositories
- Données partagées: App Group `group.com.misericode.pinpin`
- Configuration SwiftData: `ModelConfiguration(groupContainer: .identifier(AppConstants.groupID), cloudKitDatabase: .automatic)`

### SwiftData + CloudKit Setup

- Container principal: `iCloud.com.misericode.Pinpin`
- Configuration: `.cloudKitDatabase: .private(AppConstants.cloudKitContainerID)`
- **SwiftData gère TOUT automatiquement** (iOS 18+) :
  - Synchronisation CloudKit automatique
  - Merge automatique des changements entre app et extension
  - `@Query` se rafraîchit automatiquement au foreground
  - **Aucun code de sync nécessaire** - 100% natif
  - App Group permet le partage du container entre processus

### Important Patterns

1. **Repository Pattern pour SwiftData**
   - Tous les accès SwiftData passent par repositories
   - Pas d'accès direct au ModelContext depuis les Views/ViewModels
   - DataService expose une API haut niveau qui délègue aux repositories

2. **Upsert Pattern**
   - `ContentItemRepository.upsert()` et `CategoryRepository.upsert()` mergen par ID
   - Critique pour backup/restore et pour éviter les duplicatas CloudKit

3. **Catégorie "Misc" spéciale**
   - Catégorie par défaut pour items sans catégorie (constantes dans AppConstants)
   - Cleanup automatique des catégories Misc vides via `CategoryRepository.cleanupEmptyMiscCategories()`

4. **Image Storage Strategy**
   - Images stockées dans `ContentItem.imageData` (Data, optimisé max 1MB)
   - `thumbnailUrl` legacy pour compatibilité, mais imageData est preferred
   - Cleanup des URLs temporaires iOS au démarrage (MaintenanceService)

5. **Pagination**
   - Côté UI dans MainViewModel (displayLimit: 50, +50 au scroll)
   - Pas de pagination SwiftData (fetchLimit utilisé seulement dans DataService.loadContentItems)

## Code Style & Swift 6 Guidelines

⚠️ **Important**: Ces règles sont CRITIQUES et doivent être suivies:

- Utiliser `@Observable` (pas `@ObservableObject`) pour tous view models
- Utiliser `@Bindable` (pas `@State`) pour passer objets observables aux views
- Utiliser Swift 6 concurrency (async/await, actors)
- Utiliser `@MainActor` appropriément pour mises à jour UI
- Éviter Combine legacy (`@Published`) - utiliser `@Observable`
- Builder pour iOS 18.5 avec APIs récentes - pas compatibilité arrière
- Utiliser navigation SwiftUI moderne (NavigationStack, navigationDestination)
- Éviter GCD/DispatchQueue - utiliser Swift Concurrency
- Toujours utiliser xcodebuild avec flag `--quiet`

## Critical Implementation Notes

1. **Repositories MUST be @MainActor**
   - ContentItemRepository et CategoryRepository sont @MainActor
   - Tous les appels doivent être sur le main thread

2. **ModelContext Sharing**
   - DataService.shared.context est le ModelContext principal
   - Repositories créés avec ce context dans DataService
   - Share extensions créent leur propre ModelContainer mais même schema/config

3. **Category Deletion**
   - Quand on delete une category, réassigner ses items à "Misc" (voir DataService.deleteCategory)
   - Utiliser CategoryRepository.findOrCreateMiscCategory()

4. **Backup Format**
   - Version 2: items.json + images/ folder
   - items.json contient BackupFile avec categories[] et items[]
   - Images nommées {UUID}.jpg dans images/
   - Import: upsert par ID (merge, pas de duplicatas)

5. **OCR Integration**
   - Share extension fait OCR automatique sur toutes les images
   - Métadonnées stockées dans ContentItem.metadata (Data JSON)
   - Texte OCR nettoyé via OCRService.cleanOCRText()

## Targets & Extensions

- **Pinpin**: App iOS principale
- **PinpinMac**: App macOS (menu bar app)
- **PinpinShareExtension**: Share extension iOS
- **PinpinMacShareExtension**: Share extension macOS

Tous partagent:
- `Pinpin/Shared/Models/` (ContentItem, Category)
- `Pinpin/Shared/Services/` (OCRService, ImageOptimizationService)
- `Pinpin/Shared/AppConstants.swift`
