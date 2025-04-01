//
//  SpineSwiftDrawable.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_c

@objcMembers
open class SpineSwiftDrawable: NSObject {
    
    @nonobjc
    internal let pResource: SpineAnimationStateDataBox
    @nonobjc
    internal let pSkeleton: UnsafeMutablePointer<spSkeleton>
    @nonobjc
    internal let pAnimationState:UnsafeMutablePointer<spAnimationState>
    @nonobjc
    internal let pClipping = spSkeletonClipping_create()!
    @nonobjc
    private let pBoundingBox = spSkeletonBounds_create()!
    
    @objc
    public weak var animationListner: SpineAnimationListener?
    
    @nonobjc
    public init(resource: SpineAnimationStateDataBox) {
        self.pResource = resource
        
        self.pSkeleton = spSkeleton_create(resource.pSkeletonData.native)
        self.pAnimationState = spAnimationState_create(resource.native)
        super.init()
        self.pAnimationState.pointee.userData = Unmanaged.passUnretained(self).toOpaque()
        self.pAnimationState.pointee.listener = _animationEventDispatched
        spSkeleton_updateWorldTransform(pSkeleton, SP_PHYSICS_NONE)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithResource:)
    public convenience init(
        invalidForSwift spineData:SpineAnimationStateDataBox
    ) {
        self.init(resource: spineData)
    }
    
    deinit {
        spSkeletonBounds_dispose(pBoundingBox)
        spSkeleton_dispose(pSkeleton)
        spAnimationState_dispose(pAnimationState)
        spSkeletonClipping_dispose(pClipping)
    }
    
    public func update(delta: Float) {
        spAnimationState_update(pAnimationState, delta)
        spAnimationState_apply(pAnimationState, pSkeleton)

        spSkeleton_update(pSkeleton, delta)

        spSkeleton_updateWorldTransform(pSkeleton, SP_PHYSICS_UPDATE)
    }
    
    public func updateBoundingBox(updateAabb: Bool) {
        spSkeletonBounds_update(pBoundingBox, pSkeleton, updateAabb ? 1 : 0)
    }
    
    @objc open var resource: SpineAnimationStateDataBox {
        pResource
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutablePointer<spSkeleton>) -> Void
    ) {
        body(pSkeleton)
    }
    /// Do not modify listener and userData
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutablePointer<spAnimationState>) -> Void
    ) {
        body(pAnimationState)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessBoundingBox(
        _ body: (UnsafeMutablePointer<spSkeletonBounds>) -> Void
    ) {
        body(pBoundingBox)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessClipping(
        _ body: (UnsafeMutablePointer<spSkeletonClipping>) -> Void
    ) {
        body(pClipping)
    }
    
}

public extension SpineSwiftDrawable {
    /// access variable outside of the scope can be undefined behavior
    func accessSkeleton<R:~Copyable, Failure:Error>(
        _ body: (inout spSkeleton) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&pSkeleton.pointee)
    }
    /// Do not modify listener and userData
    func accessAnimation<R:~Copyable, Failure:Error>(
        _ body: (inout spAnimationState) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&pAnimationState.pointee)
    }
    /// access variable outside of the scope can be undefined behavior
    func accessBoundingBox<R:~Copyable, Failure:Error>(
        _ body: (inout spSkeletonBounds) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&pBoundingBox.pointee)
    }
    /// access variable outside of the scope can be undefined behavior
    ///
    /// clipping is used by the render command internally so using this is higly discouraged
    ///
    /// prefer creating your own clipping object
    func accessClipping<R:~Copyable, Failure:Error>(
        _ body: (inout spSkeletonClipping) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&pClipping.pointee)
    }
    
}


fileprivate func _animationEventDispatched(
    state: UnsafeMutablePointer<spAnimationState>?,
    type: spEventType,
    entry: UnsafeMutablePointer<spTrackEntry>?,
    event: UnsafeMutablePointer<spEvent>?
) {
    guard
        let userRef = state?.pointee.userData,
        let wrapper = Unmanaged<AnyObject>.fromOpaque(userRef).takeUnretainedValue() as? SpineSwiftDrawable
    else {
        return
    }
    wrapper.animationListner?.eventDispatched(drawable: wrapper, type: type, entry: entry!, event: event)
}


