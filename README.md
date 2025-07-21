# Neeed

Une application iOS pour sauvegarder et organiser vos contenus favoris avec synchronisation iCloud.

## Fonctionnalités

- 📱 Application iOS native
- 🔗 Extension de partage pour sauvegarder du contenu depuis n'importe quelle app
- ☁️ Synchronisation automatique avec iCloud via CloudKit
- 💾 Stockage local avec Core Data
- 🎵 Support pour différents types de contenu (musique, articles, etc.)

## Architecture

- **Core Data** : Stockage local des données
- **CloudKit** : Synchronisation cloud automatique
- **UserDefaults partagés** : Communication entre l'app principale et l'extension de partage
- **Share Extension** : Permet de sauvegarder du contenu depuis d'autres applications

## Configuration requise

- iOS 15.0+
- Xcode 14.0+
- Compte développeur Apple (pour CloudKit)

## Installation

1. Clonez le repository
2. Ouvrez `Neeed2.xcodeproj` dans Xcode
3. Configurez votre équipe de développement dans les paramètres du projet
4. Compilez et lancez l'application

## Structure du projet

```
Neeed2/
├── Neeed2/                 # Application principale
│   ├── Models/            # Modèles Core Data
│   ├── Views/             # Vues SwiftUI
│   ├── Services/          # Services (Core Data, CloudKit)
│   └── Neeed2.xcdatamodeld # Modèle de données Core Data
└── NeeedShareExtension/   # Extension de partage
    └── ShareViewController.swift
```

## Migration

Ce projet a été migré de Supabase vers Core Data + CloudKit pour une meilleure intégration native iOS et une synchronisation automatique avec iCloud.
