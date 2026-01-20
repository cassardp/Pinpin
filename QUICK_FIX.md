# 🚀 Quick Fix - Actions dans Xcode

## ⚡ ACTIONS (5 minutes)

### Étape 1: Ajouter ViewExtensions.swift (Shared)
```
📂 Dans Xcode: Clic droit sur "Pinpin/Shared/Core/"
   → "Add Files to Pinpin..."
   → Sélectionner: ViewExtensions.swift
   → Targets: ✅ TOUS (Pinpin, PinpinMac, PinpinShareExtension, PinpinMacShareExtension)
   → Add
```

### Étape 2: Ajouter PlatformColors.swift
```
📂 Dans Xcode: Clic droit sur "Pinpin/Shared/Core/"
   → "Add Files to Pinpin..."
   → Sélectionner: PlatformColors.swift
   → Targets: ✅ TOUS (Pinpin, PinpinMac, PinpinShareExtension, PinpinMacShareExtension)
   → Add
```

### Étape 3: Ajouter MacViewExtensions.swift (macOS uniquement)
```
📂 Dans Xcode: Clic droit sur "PinpinMac/Extensions/"
   → "Add Files to Pinpin..."
   → Sélectionner: MacViewExtensions.swift (renommé pour éviter conflit)
   → Targets: ✅ PinpinMac UNIQUEMENT
   → Add
```

### Étape 4: Supprimer l'ancien ViewExtensions.swift du target PinpinMac
```
📂 Si un fichier "ViewExtensions.swift" apparaît dans PinpinMac/Extensions/:
   → Clic droit → Delete → Remove Reference (pas Move to Trash)
   → C'est l'ancien fichier avant renommage
```

### Étape 5: Ajouter StorageStatsView au target macOS
```
📂 Dans Xcode: Sélectionner "Pinpin/Views/Utilities/Components/StorageStatsView.swift"
   → Panneau de droite: File Inspector
   → Section "Target Membership"
   → ✅ Cocher: PinpinMac (en plus de Pinpin déjà coché)
```

### Étape 6: Retirer SimilarSearchService des extensions
```
📂 Dans Xcode: Sélectionner "Pinpin/Shared/Services/SimilarSearchService.swift"
   → Panneau de droite: File Inspector
   → Section "Target Membership"
   → ✅ Garder: Pinpin, PinpinMac
   → ❌ Décocher: PinpinShareExtension, PinpinMacShareExtension
```

---

## ✅ Vérification

Après ces étapes:

```bash
# Test iOS
xcodebuild -project Pinpin.xcodeproj -scheme Pinpin \
  -destination 'generic/platform=iOS Simulator' build

# Test macOS
xcodebuild -project Pinpin.xcodeproj -scheme PinpinMac \
  -destination 'generic/platform=macOS' build
```

**Résultat attendu:** ✅ BUILD SUCCEEDED (les deux)

---

## 🔍 Problèmes Résolus

### ✅ "Multiple commands produce ViewExtensions.stringsdata"
→ Résolu en renommant le fichier macOS en `MacViewExtensions.swift`

### ✅ "Value of type 'some View' has no member 'if'"
→ Résolu en ajoutant `Shared/Core/ViewExtensions.swift` à tous les targets

### ✅ "Cannot find 'StorageStatsView' in scope" (macOS)
→ Résolu en ajoutant StorageStatsView au target PinpinMac

### ✅ "'shared' is unavailable in application extensions"
→ Résolu en retirant SimilarSearchService des ShareExtensions

---

**Note:** Si PlatformTypes.swift n'est pas encore ajouté, fais-le avec la même méthode (Étape 1).

---

## 🔧 Corrections Automatiques Effectuées

### ✅ Doublon RenameCategorySheet supprimé
- Supprimé la redéclaration dans `CategorySelectionModalWrapper.swift`
- Utilise maintenant la version partagée dans `Views/Category/Sheets/`

### ✅ Appel corrigé à RenameCategorySheet
- Mis à jour pour utiliser la nouvelle signature (name, onCancel, onSave)

### ✅ MacViewExtensions.swift renommé
- Évite le conflit avec `Shared/Core/ViewExtensions.swift`

---

## 📝 Notes Importantes

### RenameCategorySheet est maintenant partagé
Ce composant est utilisé par:
- ✅ Pinpin (iOS app)
- ✅ PinpinShareExtension (iOS)
- ✅ PinpinMacShareExtension (macOS) - si nécessaire

### Target Membership Recommandé
Le fichier `Views/Category/Sheets/RenameCategorySheet.swift` devrait être dans:
- ✅ Pinpin
- ✅ PinpinShareExtension (pour créer catégories depuis extension)
- ❌ PinpinMac (a sa propre UI)
- ❌ PinpinMacShareExtension (peut utiliser la version iOS)

