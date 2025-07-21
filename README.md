# Pinpin

**A local, privacy-friendly alternative to Pinterest: no ads, no login, all your collections are stored on your device and iCloud.**

An open-source iOS application to save and organize your favorite content, with iCloud synchronization.

## Features

- 📱 Native iOS application
- 🔗 Share Extension to save content from any app
- ☁️ Automatic synchronization with iCloud using CloudKit
- 💾 Local storage with Core Data
- 🎵 Supports multiple content types (music, articles, etc.)

## Architecture

- **Core Data**: Local data storage
- **CloudKit**: Automatic cloud synchronization
- **Shared UserDefaults**: Communication between the main app and the share extension
- **Share Extension**: Save content from other applications

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Apple Developer account (for CloudKit)

## Installation

1. Clone this repository
2. Open `Pinpin.xcodeproj` in Xcode
3. Set your development team in the project settings
4. Build and run the application

## Project Structure

```
Pinpin/
├── Pinpin/                    # Main application
│   ├── Models/                # Core Data models
│   ├── Views/                 # SwiftUI views
│   ├── Services/              # Services (Core Data, CloudKit)
│   └── Pinpin.xcdatamodeld    # Core Data model
└── PinpinShareExtension/      # Share Extension
    └── ShareViewController.swift
```

## License

This project is open source and available under the [MIT License](LICENSE).

