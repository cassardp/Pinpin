# 🔴 ERREUR: SimilarSearchService dans ShareExtension

## Problème

`SimilarSearchService` utilise `UIApplication.shared` qui n'est **PAS disponible** dans les extensions iOS/macOS.

**Erreur:**
```
'shared' is unavailable in application extensions for iOS
```

## ✅ Solution IMMÉDIATE

### Dans Xcode:

1. **Sélectionner le fichier:**
   ```
   Pinpin/Shared/Services/SimilarSearchService.swift
   ```

2. **Ouvrir File Inspector** (panneau de droite)

3. **Section "Target Membership":**
   ```
   ✅ Pinpin              (coché)
   ✅ PinpinMac           (coché)
   ❌ PinpinShareExtension        (DÉCOCHER)
   ❌ PinpinMacShareExtension     (DÉCOCHER)
   ```

4. **Sauvegarder**

## Pourquoi?

`SimilarSearchService` fait ces choses qui ne fonctionnent PAS dans une extension:

```swift
// Ligne 100, 138, 154
UIApplication.shared.connectedScenes  // ❌ Interdit dans extensions
UIApplication.shared.open()           // ❌ Interdit dans extensions
```

Les extensions ont des restrictions de sécurité et ne peuvent pas:
- Accéder à `UIApplication.shared`
- Ouvrir des URLs (sauf via `extensionContext`)
- Présenter des view controllers de l'app principale

## Résultat Attendu

Après avoir décoché les extensions:

```bash
xcodebuild -project Pinpin.xcodeproj -scheme Pinpin \
  -destination 'generic/platform=iOS Simulator' build
```

**→ BUILD SUCCEEDED** ✅

---

**C'est l'Étape 6 du guide QUICK_FIX.md**
