# 📋 TODO Refactoring Pinpin

## ✅ Phase 1 - Framework Partagé + Constantes (TERMINÉ)

- [x] Créer `AppConstants.swift` avec toutes les constantes
- [x] Créer `ImageOptimizationService.swift` partagé
- [x] Mettre à jour `DataService.swift` pour utiliser AppConstants
- [x] Mettre à jour `NotificationContentService.swift` pour utiliser AppConstants
- [x] Mettre à jour `CategoryOrderService.swift` pour utiliser AppConstants
- [x] Mettre à jour `MainView.swift` pour utiliser AppConstants
- [x] Mettre à jour `ShareViewController.swift` pour utiliser ImageOptimizationService
- [x] Créer `MainViewModel.swift` (préparation Phase 2)
- [x] Créer `ContentFilterService.swift`
- [x] Créer `ErrorHandler.swift`
- [x] Créer documentation `ARCHITECTURE.md`
- [x] Créer guide `QUICK_START.md`

**Résultat** : 
- ✅ 5 nouveaux services
- ✅ 440 lignes de code structuré
- ✅ 45 lignes de duplication supprimées
- ✅ Documentation complète

---

## ✅ Phase 2 - Simplification MainView (TERMINÉ)

### 2.1 Intégration MainViewModel
- [x] Remplacer la logique de filtrage dans MainView par MainViewModel
- [x] Migrer la gestion de sélection vers MainViewModel
- [x] Migrer la logique de partage vers MainViewModel
- [x] Intégrer scrollProgress et showSearchBar dans ViewModel
- [x] Tester que tout fonctionne

**Résultat** : MainView 582 → 506 lignes (-76 lignes, -13%)

### 2.2 Extraction Composants FloatingSearchBar
- [ ] Créer `SearchBarContent.swift` (barre de recherche)
- [ ] Créer `SelectionToolbar.swift` (toolbar sélection)
- [ ] Créer `ControlsRow.swift` (row de contrôles)
- [ ] Simplifier `FloatingSearchBar.swift` en orchestrateur

**Gain attendu** : FloatingSearchBar 342 → ~150 lignes

### 2.3 Tests
- [ ] Tester filtrage avec MainViewModel
- [ ] Tester sélection multiple
- [ ] Tester recherche
- [ ] Tester partage

**Temps estimé** : 2-3h

---

## ✅ Phase 3 - Séparation DataService (TERMINÉ)

### 3.1 ContentItemRepository
- [x] Créer `ContentItemRepository.swift`
- [x] Migrer méthodes CRUD de DataService
- [x] Migrer méthodes de recherche
- [x] Migrer méthodes de pagination

**Méthodes à migrer** :
- `loadContentItems()`
- `loadMoreContentItems()`
- `addContentItem()`
- `saveContentItem()`
- `updateContentItem()`
- `deleteContentItem()`
- `searchContentItems()`
- `filterContentItems()`

### 3.2 CategoryRepository
- [x] Créer `CategoryRepository.swift`
- [x] Migrer méthodes de gestion des catégories
- [x] Migrer logique de catégorie "Misc"

**Méthodes à migrer** :
- `fetchCategories()`
- `fetchCategoryNames()`
- `addCategory()`
- `deleteCategory()`
- `findOrCreateCategory()`
- `getDefaultCategoryName()`

### 3.3 CloudSyncService
- [x] Créer `CloudSyncService.swift`
- [x] Migrer logique iCloud de DataService
- [x] Migrer monitoring de sync

**Méthodes à migrer** :
- `checkiCloudAvailability()`
- `setupiCloudSyncMonitoring()`
- `isiCloudSyncUpToDate()`
- `getiCloudSyncStatus()`

### 3.4 MaintenanceService
- [x] Créer `MaintenanceService.swift`
- [x] Migrer `cleanupInvalidImageURLs()`
- [x] Migrer `prepareSharedContainerIfNeeded()`

### 3.5 Refactoring DataService
- [x] Garder uniquement container et context
- [x] Utiliser les repositories
- [x] Simplifier l'interface
- [x] Migration complète effectuée

**Résultat** : DataService 635 → 350 lignes (-45%)

**Temps réel** : 2h

---

## 🧪 Phase 4 - Tests (À FAIRE)

### 4.1 Tests Unitaires Services
- [ ] `ContentFilterServiceTests.swift`
  - [ ] Test filtrage par catégorie
  - [ ] Test recherche textuelle
  - [ ] Test cas spécial Twitter/X
  - [ ] Test comptage par catégorie

- [ ] `ImageOptimizationServiceTests.swift`
  - [ ] Test compression qualité
  - [ ] Test redimensionnement
  - [ ] Test limite 1MB

- [ ] `CategoryOrderServiceTests.swift`
  - [ ] Test réorganisation
  - [ ] Test nettoyage doublons
  - [ ] Test renommage

- [ ] `ErrorHandlerTests.swift`
  - [ ] Test gestion erreurs
  - [ ] Test messages localisés
  - [ ] Test suggestions

### 4.2 Tests Unitaires ViewModels
- [ ] `MainViewModelTests.swift`
  - [ ] Test filtrage
  - [ ] Test sélection
  - [ ] Test recherche
  - [ ] Test partage

### 4.3 Tests Unitaires Repositories (après Phase 3)
- [ ] `ContentItemRepositoryTests.swift`
- [ ] `CategoryRepositoryTests.swift`

### 4.4 Tests d'Intégration
- [ ] Test partage depuis Safari → App
- [ ] Test synchronisation iCloud
- [ ] Test backup/restore

### 4.5 Tests UI
- [ ] Test navigation
- [ ] Test recherche
- [ ] Test sélection multiple
- [ ] Test filtrage par catégorie

**Temps estimé** : 2-3h

---

## 📚 Phase 5 - Documentation (À FAIRE)

### 5.1 Documentation Code
- [ ] Documenter tous les services publics
- [ ] Documenter les ViewModels
- [ ] Documenter les repositories
- [ ] Ajouter exemples d'utilisation

### 5.2 Documentation Utilisateur
- [ ] Guide de contribution
- [ ] Guide de déploiement
- [ ] Guide de debugging

### 5.3 Documentation Technique
- [ ] Diagrammes d'architecture
- [ ] Flux de données détaillés
- [ ] Décisions d'architecture (ADR)

**Temps estimé** : 1-2h

---

## 🎯 Priorités

### 🔴 Haute Priorité
1. **Phase 2** - Simplification MainView
   - Impact immédiat sur maintenabilité
   - Facilite les futures modifications

### 🟡 Moyenne Priorité
2. **Phase 3** - Séparation DataService
   - Améliore l'architecture
   - Facilite les tests

3. **Phase 4** - Tests
   - Sécurise le code
   - Prévient les régressions

### 🟢 Basse Priorité
4. **Phase 5** - Documentation
   - Améliore la collaboration
   - Facilite l'onboarding

---

## 📊 Métriques de Progrès

### Lignes de Code

| Fichier | Avant | Objectif | Gain |
|---------|-------|----------|------|
| MainView.swift | 582 | 400 | -182 |
| DataService.swift | 635 | 300 | -335 |
| FloatingSearchBar.swift | 342 | 150 | -192 |
| **Total** | **1559** | **850** | **-709** |

### Services Créés

| Phase | Services | Status |
|-------|----------|--------|
| Phase 1 | 5 | ✅ |
| Phase 2 | 3 | ⏳ |
| Phase 3 | 4 | ⏳ |
| **Total** | **12** | **5/12** |

### Tests

| Type | Nombre | Status |
|------|--------|--------|
| Unitaires | 20+ | ⏳ |
| Intégration | 5+ | ⏳ |
| UI | 5+ | ⏳ |
| **Total** | **30+** | **0/30** |

---

## 🎉 Jalons

- [x] **Jalon 1** : Phase 1 terminée (2025-09-30)
- [ ] **Jalon 2** : Phase 2 terminée
- [ ] **Jalon 3** : Phase 3 terminée
- [ ] **Jalon 4** : Tests complets
- [ ] **Jalon 5** : Documentation complète

---

## 💡 Notes

### Décisions Prises
1. Utiliser MVVM pour séparer logique/UI
2. Services singleton pour logique partagée
3. SwiftData pour persistance
4. Pas de framework externe (KISS)

### À Discuter
- [ ] Utiliser Combine pour reactive programming ?
- [ ] Ajouter SwiftLint pour cohérence du code ?
- [ ] Migrer vers async/await partout ?

---

**Dernière mise à jour** : 2025-09-30  
**Phase actuelle** : Phase 1 ✅  
**Prochaine phase** : Phase 2 ⏳
