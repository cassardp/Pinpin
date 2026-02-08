# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pinpin is a local-first, privacy-respecting moodboard and bookmarking app (Pinterest alternative). It runs on iOS/iPadOS 26+ and macOS 26+, with data stored locally via SwiftData and optionally synced through CloudKit.

## Build & Run

This is an Xcode project (`Pinpin.xcodeproj`) with no external dependencies (no SPM, CocoaPods, or Carthage). Build and run using:

```bash
# Build iOS app
xcodebuild -project Pinpin.xcodeproj -scheme Pinpin -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build macOS app
xcodebuild -project Pinpin.xcodeproj -scheme PinpinMac build
```

There are no tests in this project.

## Targets

| Target | Platform | Description |
|--------|----------|-------------|
| **Pinpin** | iOS/iPadOS | Main mobile app |
| **PinpinMac** | macOS | Native Mac app (separate target, not Catalyst) |
| **PinpinShareExtension** | iOS/iPadOS | Share sheet extension |
| **PinpinMacShareExtension** | macOS | Share sheet extension |

All targets share the same CloudKit container (`iCloud.com.misericode.Pinpin`) and App Group (`group.com.misericode.pinpin`).

## Architecture

**MVVM + Services** pattern with 100% SwiftUI and SwiftData.

### Code Organization

- `Pinpin/Shared/` — Cross-platform code shared between iOS and macOS targets:
  - `Models/` — SwiftData models (`ContentItem`, `Category`, `SearchSite`)
  - `Services/` — Business logic (OCR, image optimization, similar search, database maintenance)
  - `Core/` — Platform abstraction (`PlatformTypes.swift`, `PlatformColors.swift`)
  - `AppConstants.swift` — Centralized configuration (layout metrics, spacing, fonts adapted per column count)
- `Pinpin/Views/` — iOS/iPadOS SwiftUI views
- `Pinpin/ViewModels/` — iOS ViewModels (`MainViewModel`)
- `PinpinMac/Views/` — macOS-specific SwiftUI views (parallel structure to iOS views)
- `PinpinMac/ViewModels/` — macOS ViewModels (`CategoryManager`, `MacSelectionManager`)

### Platform Abstraction

The codebase uses conditional compilation to support both platforms:
- `PlatformTypes.swift` defines type aliases: `PlatformImage` (UIImage/NSImage), `PlatformColor` (UIColor/NSColor), `PlatformViewController`
- Use `#if os(iOS)` / `#if os(macOS)` and `#if canImport(UIKit)` / `#if canImport(AppKit)` for platform-specific code
- iPad is detected at runtime via `AppConstants.isIPad`; iPad layout values are harmonized with macOS values

### Data Layer

- **SwiftData** models with CloudKit sync (private database)
- `ContentItem` always belongs to a `Category` (required for CloudKit sync integrity)
- `Category` has a `@Relationship(deleteRule: .nullify)` to `ContentItem`
- `ModelContainer` is configured with App Group + CloudKit in both app entry points
- `DatabaseMaintenanceService` runs at startup to clean up orphaned data

### Custom Pinterest Layout

Both platforms implement a custom masonry grid layout using SwiftUI's `Layout` protocol:
- `PinterestLayout` (iOS) — adapts columns for iPhone (2-4) and iPad (3-10)
- `MacPinterestLayout` (macOS) — 3-10 columns
- All layout metrics (spacing, corner radius, font sizes, padding) scale with column count via `AppConstants`

### Content Card Variants

Content is rendered polymorphically based on content type:
- `StandardContentView` — image + title/description
- `SquareContentView` — square-optimized
- `TikTokContentView` — vertical video format
- `TextOnlyContentView` — text without image
- `LinkWithoutImageView` — URL without image

## Conventions

- Language: Swift code comments and UI strings are in **French**
- Communicate with the developer in **French**
- ViewModels use the `@Observable` macro with `@MainActor`
- SwiftData queries use `@Query` for reactive UI binding
- The app uses `.system(.body, design: .rounded)` as base font on iOS
- macOS windows use `.windowStyle(.hiddenTitleBar)` with 1200x800 default size
