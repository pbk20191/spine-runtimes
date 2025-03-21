//
//  SpineAnimationListener.swift
//  spine-ios
//
//  Created by 박병관 on 3/16/25.
//
import spine_c
import Foundation

@objc
public protocol SpineAnimationListener: NSObjectProtocol {
    
    
    func eventDispatched(
        drawable: SpineSwiftDrawable,
        type: spEventType,
        entry: UnsafeMutablePointer<spTrackEntry>,
        event: UnsafePointer<spEvent>?
    )
    
}
