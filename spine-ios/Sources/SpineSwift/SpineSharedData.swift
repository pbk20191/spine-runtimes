//
//  SpineSharedData.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_c
#if canImport(MetalKit)
import MetalKit
#endif

@objcMembers
open class SpineSharedData: NSObject {
    
    @nonobjc
    internal let skeletonData: UnsafeMutablePointer<spSkeletonData>
    @nonobjc
    internal let animationStateData: UnsafeMutablePointer<spAnimationStateData>
    @nonobjc
    internal let atlas: UnsafeMutablePointer<spAtlas>
    
    // takes the ownership of the skeletonData and atlas
    @nonobjc
    public init(
        atlas: UnsafeMutablePointer<spAtlas>,
        skeletonData: UnsafeMutablePointer<spSkeletonData>
    ) {
        
        self.skeletonData = skeletonData
        self.atlas = atlas
        self.animationStateData = spAnimationStateData_create(skeletonData)
        super.init()
    }

    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skeletonData:)
    public convenience init(
        invalidForSwift skeletonData:UnsafeMutablePointer<spSkeletonData>,
        invalidForSwift atlas:UnsafeMutablePointer<spAtlas>
    ) {
        /**
         exposing designated-initializer to  objective-c interface creates all kind of trouble when making swift subclass
         so only expose convenience initializer to prevent that issue
         */
        self.init(atlas: atlas, skeletonData: skeletonData)
    }
    
    deinit {
        spAnimationStateData_dispose(animationStateData)
        spSkeletonData_dispose(skeletonData)
        spAtlas_dispose(atlas)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutablePointer<spSkeletonData>) -> Void
    ) {
        body(skeletonData)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutablePointer<spAnimationStateData>) -> Void
    ) {
        body(animationStateData)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (UnsafeMutablePointer<spAtlas>) -> Void
    ) {
        body(atlas)
    }
    

    
}


public extension SpineSharedData {
    
    func accessSkeleton<R:~Copyable, Failure:Error>(
        _ body: (inout spSkeletonData) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&skeletonData.pointee)
    }
    
    func accessAnimation<R:~Copyable, Failure:Error>(
        _ body: (inout spAnimationStateData) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&animationStateData.pointee)
    }
    
    func accessAtlas<R:~Copyable, Failure:Error>(
        _ body:  (inout spAtlas) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&atlas.pointee)
    }
    
}
