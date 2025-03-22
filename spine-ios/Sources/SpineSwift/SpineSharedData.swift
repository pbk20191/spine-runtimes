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
    public init(
        skeletonData: UnsafeMutablePointer<spSkeletonData>,
        atlas: UnsafeMutablePointer<spAtlas>
    ) {
        
        self.skeletonData = skeletonData
        self.atlas = atlas
        self.animationStateData = spAnimationStateData_create(skeletonData)
        super.init()
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
