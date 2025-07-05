//
//  SpineSwiftDrawable.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_c

open class SpineSwiftDrawable: NSObject {
    
    @usableFromInline
    struct AnimationStateCleaner: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spAnimationState>) {
            spAnimationState_dispose(pointer)
        }
        
    }
    
    @usableFromInline
    struct SkeletonCleaner: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spSkeleton>) {
            spSkeleton_dispose(pointer)
        }
        
    }
    
    @usableFromInline typealias SkeletonBox = PointeeBox<spSkeleton, SkeletonCleaner>
    @usableFromInline typealias AnimationStateBox = PointeeBox<spAnimationState, AnimationStateCleaner>
    
    @nonobjc
    internal let pResource: SpineAnimationStateDataBox
    @nonobjc
    internal let pSkeletonBox: SkeletonBox
    @nonobjc
    internal let pAnimationStateBox: AnimationStateBox

    @objc
    public weak var animationListner: SpineAnimationListener?


    
    @nonobjc
    public init(resource: SpineAnimationStateDataBox) {
        self.pResource = resource
        
        let pSkeleton = spSkeleton_create(&resource.pSkeletonData[])!
        let pAnimationState = spAnimationState_create(&resource[])!
        self.pSkeletonBox = .init(pSkeleton)
        self.pAnimationStateBox = .init(pAnimationState)
        super.init()
        
        pAnimationState.pointee.userData = Unmanaged.passUnretained(self).toOpaque()
        pAnimationState.pointee.listener = Self._eventDispatcher
        spSkeleton_updateWorldTransform(pSkeleton, SP_PHYSICS_NONE)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithResource:)
    public convenience init(
        invalidForSwift spineData:SpineAnimationStateDataBox
    ) {
        self.init(resource: spineData)
    }

    @objc
    public func update(delta: Float) {
        spAnimationState_update(&self.pAnimationStateBox[], delta)
        spAnimationState_apply(&self.pAnimationStateBox[], &self.pSkeletonBox[])

        spSkeleton_update(&self.pSkeletonBox[], delta)

        spSkeleton_updateWorldTransform(&self.pSkeletonBox[], SP_PHYSICS_UPDATE)
    }
    
    @objc open var resource: SpineAnimationStateDataBox {
        pResource
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutablePointer<spSkeleton>) -> Void
    ) {
        body(&self.pSkeletonBox[])
    }
    /// Do not modify listener and userData
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutablePointer<spAnimationState>) -> Void
    ) {
        body(&self.pAnimationStateBox[])
    }
    
    @inline(__always)
    public var skeleton: spSkeleton {
        @inline(__always)
        borrowing _modify {
            yield &self.pSkeletonBox[]
        }
        @inline(__always)
        borrowing _read {
            yield self.pSkeletonBox[]
        }
    }
    
    /// Do not modify listener and userData
    @inline(__always)
    public var animationState: spAnimationState {
        @inline(__always)
        borrowing _modify {
            yield &self.pAnimationStateBox[]
        }
        @inline(__always)
        _read {
            yield self.pAnimationStateBox[]
        }
    }
    
    @inline(__always)
    @usableFromInline
    @nonobjc
    internal static var _eventDispatcher:spAnimationStateListener {
        { state, type, entry, event in
            let drawable: SpineSwiftDrawable
            #if DEBUG
            guard
                let userRef = state?.pointee.userData,
                let wrapper = Unmanaged<AnyObject>.fromOpaque(userRef).takeUnretainedValue() as? SpineSwiftDrawable
            else {
                assertionFailure("SpineSwiftDrawable must have userData set to itself")
                return
            }
            drawable = wrapper
            #else
            drawable = Unmanaged<SpineSwiftDrawable>.fromOpaque(state!.pointee.userData).takeUnretainedValue()
            #endif
            drawable.dispatch(state: state, type: type, entry: entry, event: event)
        }
    }
    
    @inline(__always)
    @usableFromInline
    @nonobjc
    internal final func dispatch(
        state: UnsafeMutablePointer<spAnimationState>!,
        type: spEventType,
        entry: UnsafeMutablePointer<spTrackEntry>!,
        event: UnsafePointer<spEvent>?
    ) {
        assert(state == &self.pAnimationStateBox[], "state must be the same as self.animationState")
        trackMoved(entry: entry, to: type, event: event)
        animationListner?.eventDispatched(drawable: self, type: type, entry: entry!, event: event)
    }
    
    @objc
    open func trackMoved(entry: UnsafeMutablePointer<spTrackEntry>, to type:spEventType, event: UnsafePointer<spEvent>?) {

    }

}
