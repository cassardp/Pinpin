# 📦 Dossier Shared

Ce dossier contient le code partagé entre **Pinpin (iOS)** et **PinpinShareExtension**.

## 🎯 Pourquoi ?

Éviter la duplication de code entre l'app principale et l'extension de partage. Un seul modèle SwiftData = une seule source de vérité.

## 📁 Structure

```
Shared/
├── Models/
│   ├── ContentItem.swift   ✅ Partagé entre targets
│   └── Category.swift       ✅ Partagé entre targets
└── Services/
    └── ImageOptimizationService.swift  ✅ Partagé entre targets
```

## ⚙️ Configuration Xcode

Les fichiers de ce dossier sont configurés dans le `project.pbxproj` avec le système `PBXFileSystemSynchronizedBuildFileExceptionSet` pour appartenir à plusieurs targets :

- ✅ **Pinpin** (app principale)
- ✅ **PinpinShareExtension** (extension de partage iOS)

## 🚨 Règle importante

**JAMAIS dupliquer ces modèles dans d'autres targets.** Si tu as besoin d'un modèle dans un nouveau target :

1. Ouvre Xcode
2. Sélectionne le fichier dans le dossier `Shared`
3. File Inspector → Target Membership
4. Coche le nouveau target

## 🧪 Vérifier la config

```bash
# Vérifier que les modèles sont bien partagés
grep -A 5 "PinpinShareExtension.*target" Pinpin.xcodeproj/project.pbxproj | grep -E "Category|ContentItem"
```

Ça devrait afficher :
```
Shared/Models/Category.swift,
Shared/Models/ContentItem.swift,
```
