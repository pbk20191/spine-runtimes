//
//  SpineSwiftDrawable.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_c

open class SpineSwiftDrawable: NSObject {
    
    @nonobjc
    internal let pResource: SpineAnimationStateDataBox
    @nonobjc
    internal let pSkeleton: UnsafeMutablePointer<spSkeleton>
    @nonobjc
    internal let pAnimationState:UnsafeMutablePointer<spAnimationState>
    
    @objc
    public weak var animationListner: SpineAnimationListener?


    
    @nonobjc
    public init(resource: SpineAnimationStateDataBox) {
        self.pResource = resource
        
        self.pSkeleton = spSkeleton_create(resource.pSkeletonData.nativePointer)
        self.pAnimationState = spAnimationState_create(resource.nativePointer)
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
        spSkeleton_dispose(pSkeleton)
        spAnimationState_dispose(pAnimationState)
    }
    
    @objc
    public func update(delta: Float) {
        spAnimationState_update(pAnimationState, delta)
        spAnimationState_apply(pAnimationState, pSkeleton)

        spSkeleton_update(pSkeleton, delta)

        spSkeleton_updateWorldTransform(pSkeleton, SP_PHYSICS_UPDATE)
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
    
    public var skeleton: spSkeleton {
        unsafeAddress {
            .init(pSkeleton)
        }
        unsafeMutableAddress {
           pSkeleton
        }
    }
    
    /// Do not modify listener and userData
    public var animationState: spAnimationState {
        unsafeAddress {
            .init(pAnimationState)
        }
        unsafeMutableAddress {
            pAnimationState
        }
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
