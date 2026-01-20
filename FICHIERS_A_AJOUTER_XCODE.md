# Fichiers à Ajouter dans Xcode - Checklist

## 📋 Instructions Générales

Pour chaque fichier listé ci-dessous:
1. Dans Xcode, cliquer avec le bouton droit sur le dossier parent indiqué
2. Choisir **"Add Files to Pinpin..."**
3. Naviguer et sélectionner le fichier
4. ✅ Cocher les targets indiqués dans la colonne "Targets"
5. Cliquer **Add**

---

## 🆕 Nouveaux Fichiers à Ajouter

### Shared/Core/ (3 fichiers)

| Fichier | Targets à Cocher |
|---------|------------------|
| `PlatformTypes.swift` | ✅ Pinpin<br>✅ PinpinMac<br>✅ PinpinShareExtension<br>✅ PinpinMacShareExtension |
| `PlatformColors.swift` | ✅ Pinpin<br>✅ PinpinMac<br>✅ PinpinShareExtension<br>✅ PinpinMacShareExtension |
| `ViewExtensions.swift` | ✅ Pinpin<br>✅ PinpinMac<br>✅ PinpinShareExtension<br>✅ PinpinMacShareExtension |

### PinpinMac/Extensions/ (1 fichier)

| Fichier | Targets à Cocher |
|---------|------------------|
| `ViewExtensions.swift` | ✅ PinpinMac uniquement |

---

## 📦 Fichiers Déplacés à Re-Ajouter

Si des fichiers apparaissent en rouge dans Xcode, les supprimer (Remove Reference) puis les rajouter:

### Shared/Models/

| Fichier | Targets à Cocher |
|---------|------------------|
| `SearchSite.swift` | ✅ Pinpin<br>✅ PinpinMac<br>✅ PinpinShareExtension<br>✅ PinpinMacShareExtension |

### Shared/Services/

| Fichier | Targets à Cocher |
|---------|------------------|
| `ImageUploadService.swift` | ✅ Pinpin<br>✅ PinpinMac<br>✅ PinpinShareExtension<br>✅ PinpinMacShareExtension |
| `SimilarSearchService.swift` | ✅ Pinpin<br>✅ PinpinMac<br>❌ PinpinShareExtension<br>❌ PinpinMacShareExtension |

**⚠️ IMPORTANT pour SimilarSearchService:**
- NE PAS cocher les targets ShareExtension
- Utilise `UIApplication.shared` qui n'est pas disponible dans les extensions

### Views/ (Tous les sous-dossiers)

Si les fichiers dans `Views/` apparaissent en rouge:

| Dossier | Fichiers | Targets |
|---------|----------|---------|
| `Views/Screens/` | MainView.swift<br>ItemDetailView.swift<br>SettingsView.swift | ✅ Pinpin |
| `Views/Navigation/` | FilterMenuView.swift<br>FloatingSearchBar.swift<br>PushingSideDrawer.swift | ✅ Pinpin |
| `Views/Content/` | Tous les .swift | ✅ Pinpin |
| `Views/Category/` | CategorySelectionModal.swift | ✅ Pinpin<br>✅ PinpinShareExtension |
| `Views/Category/Sheets/` | Tous les .swift | ✅ Pinpin |
| `Views/Utilities/Components/` | CategoryListRow.swift<br>SmartAsyncImage.swift<br>**StorageStatsView.swift** | ✅ Pinpin<br>✅ **PinpinMac** (pour StorageStatsView) |

**⚠️ IMPORTANT pour StorageStatsView:**
- Doit être ajouté au target **PinpinMac** car utilisé dans `MacMainView.swift`

---

## 🔧 Corrections dans Build Phases

### 1. Supprimer Doublon RenameCategorySheet

1. Projet → Target **Pinpin** → Onglet **Build Phases**
2. Dérouler **Compile Sources**
3. Rechercher `RenameCategorySheet.swift`
4. Si présent **2 fois**, supprimer une occurrence (bouton -)

### 2. Vérifier Target Membership de SimilarSearchService

1. Sélectionner `Shared/Services/SimilarSearchService.swift`
2. Panneau de droite → **File Inspector**
3. Section **Target Membership**:
   - ✅ Pinpin
   - ✅ PinpinMac
   - ❌ PinpinShareExtension (décocher si coché)
   - ❌ PinpinMacShareExtension (décocher si coché)

---

## ✅ Vérification Finale

Après avoir ajouté tous les fichiers:

```bash
# Build iOS
xcodebuild -project Pinpin.xcodeproj -scheme Pinpin \
  -destination 'generic/platform=iOS Simulator' build

# Build macOS  
xcodebuild -project Pinpin.xcodeproj -scheme PinpinMac \
  -destination 'generic/platform=macOS' build
```

Les deux doivent afficher: **BUILD SUCCEEDED** ✅

---

## 🆘 Aide Rapide

### Comment ajouter un fichier dans Xcode?
1. Clic droit sur le dossier dans Project Navigator
2. "Add Files to Pinpin..."
3. Sélectionner le fichier
4. Cocher les bons targets
5. Add

### Comment vérifier les targets d'un fichier?
1. Sélectionner le fichier dans Project Navigator
2. Panneau de droite → File Inspector (icône document)
3. Section "Target Membership" liste tous les targets

### Comment supprimer un doublon dans Build Phases?
1. Projet (icône bleue) → Target → Build Phases
2. Compile Sources → Trouver le fichier
3. Bouton `-` pour supprimer

---

## 📊 Résumé

- **4 nouveaux fichiers** à ajouter
- **StorageStatsView** à ajouter au target PinpinMac
- **SimilarSearchService** à retirer des extensions
- **RenameCategorySheet** doublon à supprimer

**Temps estimé: 5-10 minutes**

---

## 🔥 ERREUR ACTUELLE À CORRIGER EN PRIORITÉ

### Erreur: "Value of type 'some View' has no member 'if'"

**Cause:** Le fichier `ViewExtensions.swift` dans `Shared/Core/` n'est pas encore ajouté au projet.

**Solution IMMÉDIATE:**

1. Dans Xcode, clic droit sur le dossier `Pinpin/Shared/Core/`
2. **"Add Files to Pinpin..."**
3. Sélectionner `ViewExtensions.swift`
4. ✅ Cocher TOUS les targets:
   - Pinpin
   - PinpinMac
   - PinpinShareExtension
   - PinpinMacShareExtension
5. Cliquer **Add**

**Puis re-build:**
```bash
xcodebuild -project Pinpin.xcodeproj -scheme Pinpin -destination 'generic/platform=iOS Simulator' build
```

Cette action va résoudre l'erreur `.if()` dans tous les targets.

