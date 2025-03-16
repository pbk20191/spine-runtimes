//
//  SpineSwiftDrawable.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_c


open class SpineSwiftDrawable: NSObject {
    
    
    public let resource: SpineSharedData
    internal let pSkeleton: UnsafeMutablePointer<spSkeleton>
    internal let pAnimationState:UnsafeMutablePointer<spAnimationState>
    internal let pClipping = spSkeletonClipping_create()!
    private let pBoundingBox = spSkeletonBounds_create()!
    
    @objc
    public weak var animationListner: SpineAnimationListener?
    
    @nonobjc
    public init(resource: SpineSharedData) {
        self.resource = resource
        
        self.pSkeleton = spSkeleton_create(resource.skeletonData)
        self.pAnimationState = spAnimationState_create(resource.animationStateData)
        super.init()
        self.pAnimationState.pointee.userData = Unmanaged.passUnretained(self).toOpaque()
        self.pAnimationState.pointee.listener = _animationEventDispatched
        spSkeleton_updateWorldTransform(pSkeleton, SP_PHYSICS_NONE)
    }
    
    deinit {
        spSkeletonClipping_dispose(pClipping)
        spSkeletonBounds_dispose(pBoundingBox)
        spSkeleton_dispose(pSkeleton)
        spAnimationState_dispose(pAnimationState)
    }
    
    func update(delta: Float) {
        spAnimationState_update(pAnimationState, delta)
        spAnimationState_apply(pAnimationState, pSkeleton)

        spSkeleton_update(pSkeleton, delta)

        spSkeleton_updateWorldTransform(pSkeleton, SP_PHYSICS_UPDATE)
    }
    
    func updateBoundingBox(updateAabb: Bool) {
        spSkeletonBounds_update(pBoundingBox, pSkeleton, updateAabb ? 1 : 0)
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
    
    func accessBoundingBox<R:~Copyable, Failure:Error>(
        _ body: (inout spSkeletonBounds) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&pBoundingBox.pointee)
    }
    
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


