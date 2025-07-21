# Guide de Renommage Complet pour Neeed2

## 🎯 Étapes de Renommage Sécurisé

### Phase 1 : Préparation
- [ ] Faire une sauvegarde complète du projet
- [ ] Commiter tous les changements Git
- [ ] Fermer Xcode complètement

### Phase 2 : Renommage Principal dans Xcode

1. **Ouvrir le projet dans Xcode**
   - [ ] Ouvrir `Neeed2.xcodeproj`

2. **Renommer le projet**
   - [ ] Dans le Project Navigator (gauche), cliquer sur "Neeed2" (racine du projet)
   - [ ] Dans le File Inspector (droite), section "Identity and Type"
   - [ ] Changer le champ "Name" de "Neeed2" vers le nouveau nom
   - [ ] Appuyer sur Enter

3. **Gérer la boîte de dialogue de renommage**
   - [ ] Xcode affiche une liste des éléments à renommer
   - [ ] Vérifier que tous les éléments pertinents sont cochés
   - [ ] Cliquer sur "Rename"

### Phase 3 : Renommage des Schemes

4. **Renommer le scheme**
   - [ ] Cliquer sur le scheme actif (en haut, à côté du bouton Run)
   - [ ] Sélectionner "Manage Schemes..."
   - [ ] Double-cliquer sur "Neeed2" et renommer
   - [ ] Cliquer sur "Close"

### Phase 4 : Renommage des Dossiers (Hors Xcode)

5. **Fermer Xcode**

6. **Renommer les dossiers physiques**
   - [ ] Dans le Finder, renommer le dossier principal du projet
   - [ ] Renommer le dossier source "Neeed2" à l'intérieur
   - [ ] Renommer "Neeed2.xcodeproj" si nécessaire

7. **Rouvrir le projet dans Xcode**

### Phase 5 : Mise à jour des Références

8. **Mettre à jour les chemins dans Build Settings**
   - [ ] Project Navigator → Sélectionner le projet
   - [ ] Build Settings → Rechercher "plist"
   - [ ] Mettre à jour le chemin Info.plist
   - [ ] Mettre à jour "Product Bundle Identifier"

9. **Pour SwiftUI : Mettre à jour Development Assets**
   - [ ] Build Settings → Rechercher "Development Assets"
   - [ ] Mettre à jour le chemin si nécessaire

### Phase 6 : Configurations Spécifiques

10. **Core Data**
    - [ ] Renommer le fichier .xcdatamodeld
    - [ ] Mettre à jour les références dans le code

11. **App Groups (pour l'extension de partage)**
    - [ ] Vérifier que "group.com.misericode.pinpin" reste inchangé
    - [ ] OU créer un nouveau App Group si changement complet

12. **Extension de Partage**
    - [ ] Renommer le dossier de l'extension
    - [ ] Mettre à jour Display Name dans Info.plist

### Phase 7 : Finalisation

13. **Nettoyer et Reconstruire**
    - [ ] Product → Clean Build Folder (Cmd+Shift+K)
    - [ ] Product → Build (Cmd+B)

14. **Tester**
    - [ ] Lancer l'app sur simulateur
    - [ ] Tester l'extension de partage
    - [ ] Vérifier Core Data fonctionne

### Phase 8 : Mise à jour des Identifiants Apple

15. **Si publication App Store prévue**
    - [ ] Créer un nouveau Bundle ID dans Apple Developer
    - [ ] Mettre à jour les Capabilities
    - [ ] Créer nouveaux provisioning profiles

## ⚠️ Points d'Attention Spécifiques à Neeed2

1. **Core Data** : Le modèle de données doit être renommé avec précaution
2. **App Group** : Utilisé pour le partage entre app et extension
3. **SharedImageService** : Vérifie les chemins de fichiers
4. **Bundle Identifier** : Actuellement "com.neeed.Neeed2"

## 🔄 Alternative : Duplication du Projet

Si vous préférez être ultra-prudent :
1. Dupliquer tout le dossier du projet
2. Suivre les étapes ci-dessus sur la copie
3. Tester complètement avant de supprimer l'original

## 📝 Checklist Finale

- [ ] L'app se lance sans erreur
- [ ] L'extension de partage fonctionne
- [ ] Les images se sauvegardent correctement
- [ ] Core Data charge les données existantes
- [ ] Pas d'avertissements de build
