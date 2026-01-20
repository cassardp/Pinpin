# Actions Xcode - Guide Visuel Simple

## 🎯 Tu as 6 actions à faire dans Xcode

### ✅ Action 1: Ajouter ViewExtensions.swift

```
1. Clic droit sur le dossier "Pinpin/Shared/Core/" dans Xcode
2. "Add Files to Pinpin..."
3. Sélectionner: ViewExtensions.swift
4. Cocher TOUS les targets:
   ✅ Pinpin
   ✅ PinpinMac
   ✅ PinpinShareExtension
   ✅ PinpinMacShareExtension
5. Cliquer "Add"
```

### ✅ Action 2: Ajouter PlatformColors.swift

```
1. Clic droit sur "Pinpin/Shared/Core/"
2. "Add Files to Pinpin..."
3. Sélectionner: PlatformColors.swift
4. Cocher TOUS les targets (comme ci-dessus)
5. Cliquer "Add"
```

### ✅ Action 3: Ajouter MacViewExtensions.swift

```
1. Clic droit sur "PinpinMac/Extensions/"
2. "Add Files to Pinpin..."
3. Sélectionner: MacViewExtensions.swift
4. Cocher UNIQUEMENT:
   ✅ PinpinMac
5. Cliquer "Add"
```

### ✅ Action 4: Ajouter StorageStatsView au target macOS

```
1. Dans Project Navigator, cliquer sur:
   Pinpin/Views/Utilities/Components/StorageStatsView.swift
   
2. Dans le panneau de DROITE → File Inspector (icône document)

3. Section "Target Membership":
   ✅ Pinpin (déjà coché)
   ✅ PinpinMac (COCHER CETTE CASE)
```

### ✅ Action 5: Retirer SimilarSearchService des extensions ⚠️ IMPORTANT

```
1. Cliquer sur: Pinpin/Shared/Services/SimilarSearchService.swift

2. Panneau de DROITE → File Inspector

3. Section "Target Membership":
   ✅ Pinpin (garder coché)
   ✅ PinpinMac (garder coché)
   ❌ PinpinShareExtension (DÉCOCHER)
   ❌ PinpinMacShareExtension (DÉCOCHER)
```

**Pourquoi?** Ce fichier utilise `UIApplication.shared` qui est interdit dans les extensions.

### ✅ Action 6 (Optionnel): Vérifier RenameCategorySheet

```
1. Cliquer sur: Pinpin/Views/Category/Sheets/RenameCategorySheet.swift

2. Panneau de DROITE → File Inspector

3. Section "Target Membership":
   ✅ Pinpin
   ✅ PinpinShareExtension
   
Si le fichier apparaît 2 fois dans Build Phases:
   → Projet → Target Pinpin → Build Phases → Compile Sources
   → Chercher "RenameCategorySheet.swift"
   → Supprimer le doublon (bouton -)
```

---

## 🧪 Test Final

Après ces 6 actions:

```bash
# Test iOS
xcodebuild -project Pinpin.xcodeproj -scheme Pinpin \
  -destination 'generic/platform=iOS Simulator' build

# Test macOS
xcodebuild -project Pinpin.xcodeproj -scheme PinpinMac \
  -destination 'generic/platform=macOS' build
```

**Les deux doivent afficher:** ✅ **BUILD SUCCEEDED**

---

## 🆘 Aide Rapide

### Comment trouver le File Inspector?
- Sélectionner un fichier dans Project Navigator (panneau de gauche)
- Regarder le panneau de DROITE
- Cliquer sur l'icône "document" (premier icône en haut)

### Comment trouver Target Membership?
- Dans File Inspector (panneau de droite)
- Scroller jusqu'à voir "Target Membership"
- Liste de cases à cocher

### Où est Project Navigator?
- Panneau de GAUCHE dans Xcode
- Arborescence de tous les fichiers du projet

---

**Temps estimé: 5 minutes** ⏱️

Une fois terminé, les builds iOS et macOS devraient passer! 🎉
