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


open class SpineAtlasBox: NSObject {
    
    @nonobjc internal let native: UnsafeMutablePointer<spAtlas>
    
    @nonobjc
    public init(atlas: UnsafeMutablePointer<spAtlas>) {
        self.native = atlas
        super.init()
        
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:)
    public convenience init(notForSwift atlas: UnsafeMutablePointer<spAtlas>) {
        self.init(atlas: atlas)
    }
    
    deinit {
        spAtlas_dispose(native)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (UnsafeMutablePointer<spAtlas>) -> Void
    ) {
        body(native)
    }
    
    
}

open class SpineSkeletonDataBox: NSObject {
        
    @nonobjc
    internal let pAtlas: SpineAtlasBox
    @nonobjc
    internal let native: UnsafeMutablePointer<spSkeletonData>
    
    // expects skeletonData is created from the given atlas
    @nonobjc
    public init(
        atlas: SpineAtlasBox,
        skeletonData: UnsafeMutablePointer<spSkeletonData>
    ) {
        self.pAtlas = atlas
        self.native = skeletonData
        super.init()
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skeletonData:)
    public convenience init(
        invalidForSwift atlas:SpineAtlasBox,
        invalidForSwift skeletonData:UnsafeMutablePointer<spSkeletonData>
    ) {
        self.init(atlas: atlas, skeletonData: skeletonData)
    }
    
    deinit {
        spSkeletonData_dispose(native)
    }
    
    @objc
    open var atlas: SpineAtlasBox { pAtlas }
        
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutablePointer<spSkeletonData>) -> Void
    ) {
        body(native)
    }
    
    
}

open class SpineAnimationStateDataBox: NSObject {
        
    @nonobjc
    internal let pSkeletonData: SpineSkeletonDataBox
    @nonobjc
    internal let native: UnsafeMutablePointer<spAnimationStateData>
    
    @nonobjc
    public init(
        skeletonData: SpineSkeletonDataBox,
        animationStateData: UnsafeMutablePointer<spAnimationStateData>
    ) {
        precondition(skeletonData.native == animationStateData.pointee.skeletonData, "skeletonData and animationStateData must be from the same source")
        self.pSkeletonData = skeletonData
        self.native = animationStateData
        super.init()
    }
    
    @objc
    public convenience init(skeletonData: SpineSkeletonDataBox) {
        self.init(
            skeletonData: skeletonData,
            animationStateData: spAnimationStateData_create(skeletonData.native)
        )
    }
    
    deinit {
        spAnimationStateData_dispose(native)
    }
    
    
    @objc
    open var skeletonData: SpineSkeletonDataBox { pSkeletonData }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutablePointer<spAnimationStateData>) -> Void
    ) {
        body(native)
    }
    
}

public extension SpineSkeletonDataBox {
    
    func accessSkeleton<R:~Copyable, Failure:Error>(
        _ body: (inout spSkeletonData) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&native.pointee)
    }
    
}

public extension SpineAnimationStateDataBox {
    func accessAnimation<R:~Copyable, Failure:Error>(
        _ body: (inout spAnimationStateData) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&native.pointee)
    }
    
}

public extension SpineAtlasBox {
    
    func accessAtlas<R:~Copyable, Failure:Error>(
        _ body:  (inout spAtlas) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&native.pointee)
    }
    
}
