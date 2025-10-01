# Test OCR macOS Share Extension

## ✅ Modifications apportées

### 1. **OCRService.swift** (nouveau fichier)
- Service OCR pour macOS utilisant Vision Framework
- Extraction de texte en mode `.accurate`
- Support français et anglais
- Nettoyage automatique du texte extrait

### 2. **ShareViewController.swift** (modifié)
- Ajout de `import Vision`
- Intégration de l'OCR lors du traitement de l'image
- Utilisation d'un semaphore pour attendre la fin de l'OCR
- Stockage du texte OCR dans les métadonnées JSON
- Passage du paramètre `ocrText` à `saveToSwiftData()`

## 🔧 Configuration requise

### Dans Xcode :
1. Ouvrir le projet `Pinpin.xcodeproj`
2. Sélectionner le target **PinpinMacShareExtension**
3. Vérifier que `OCRService.swift` est bien coché dans **Target Membership**
4. Vérifier que `Vision.framework` est bien lié

### Vérification des frameworks :
- ✅ Vision.framework
- ✅ AppKit
- ✅ SwiftData
- ✅ LinkPresentation

## 📝 Flux d'exécution

```
1. URL partagée → LPMetadataProvider
2. Récupération de l'image → NSImage
3. Redimensionnement (max 800px)
4. Compression JPEG (70%)
5. ⭐ OCR avec Vision (nouveau !)
6. Stockage dans SwiftData avec métadonnées
```

## 🧪 Test manuel

1. Compiler le projet macOS
2. Partager une URL avec une image contenant du texte
3. Vérifier dans les logs :
   ```
   [OCRService] Texte extrait: [texte détecté]
   [ShareExtension] OCR extrait: [texte nettoyé]
   ```
4. Ouvrir l'app Pinpin
5. Le texte OCR devrait être dans les métadonnées de l'item

## 🔍 Debugging

Si l'OCR ne fonctionne pas :
- Vérifier que Vision.framework est bien lié
- Vérifier les logs dans Console.app
- Filtrer par "OCRService" ou "ShareExtension"
- Vérifier que l'image n'est pas trop petite (min 50x50px)

## 📊 Comparaison iOS vs macOS

| Fonctionnalité | iOS | macOS |
|----------------|-----|-------|
| OCR Vision | ✅ | ✅ (nouveau) |
| YOLO Detection | ✅ | ❌ |
| Couleur dominante | ✅ | ❌ |
| Classification auto | ✅ | ❌ |
| Compression image | ✅ | ✅ |
| Métadonnées OCR | ✅ | ✅ (nouveau) |

## 🎯 Prochaines étapes (optionnel)

Si tu veux aller plus loin :
1. Ajouter YOLO sur macOS (comme iOS)
2. Ajouter la détection de couleur dominante
3. Ajouter la classification automatique
4. Unifier le code iOS/macOS dans un module partagé
