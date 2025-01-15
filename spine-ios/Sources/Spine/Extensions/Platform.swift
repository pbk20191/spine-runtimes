//
//  Platform.swift
//  spine-ios
//
//  Created by 박병관 on 1/16/25.
//


#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

import SwiftUI


#if canImport(UIKit)
public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
#elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
#else
#error("Unsupported platform")
#endif

#if os(iOS)

public typealias SpineUIView = SpineMetalView
#endif

#if canImport(UIKit)
public typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
public typealias PlatformViewRepresentable = NSViewRepresentable
#endif
