//
//  PlatformTypes.swift
//  Pinpin
//
//  Typealias centralisés pour la compatibilité multi-platform (iOS & macOS)
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
public typealias PlatformViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
public typealias PlatformViewController = NSViewController
#endif
