//
//  SpineSwiftDrawable.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_cpp

open class SpineSwiftDrawable: NSObject {
    
    @usableFromInline
    struct AnimationStateCleaner: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spine.AnimationState>) {
            spine_support.dispose_animationState(pointer)
        }
        
    }
    
    @usableFromInline
    struct SkeletonCleaner: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spine.Skeleton>) {
            spine_support.dispose_skeleton(pointer)
//            spine.SpineExtension.free(pointer, k.utf8Start, #line)
        }
        
    }
    
    @usableFromInline typealias SkeletonBox = PointeeBox<spine.Skeleton, SkeletonCleaner>
    @usableFromInline typealias AnimationStateBox = PointeeBox<spine.AnimationState, AnimationStateCleaner>
    
    @nonobjc
    internal let pResource: SpineAnimationStateDataBox
    @nonobjc
    internal let pSkeletonBox: SkeletonBox
    @nonobjc
    internal let pAnimationStateBox: AnimationStateBox


    @nonobjc
    public init(resource: SpineAnimationStateDataBox) {
        self.pResource = resource
        do {
            let pSkeleton = spine_support.create_skeleton(&resource.skeletonData[])!
            self.pSkeletonBox = .init(pSkeleton)
        }
        do {
            let pAnimationState = spine_support.create_animationState(&resource[])!
            self.pAnimationStateBox = .init(pAnimationState)
        }
  
        super.init()
        
        withUnsafeMutablePointer(to: &self.skeleton) {
            $0.pointee.updateWorldTransform(spine.Physics_None)
        }
//        self.skeleton.updateWorldTransform(spine.Physics_None);
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
        self.animationState.update(delta)
        self.animationState.apply(&self.skeleton)
        self.skeleton.update(delta)
        self.skeleton.updateWorldTransform(spine.Physics_Update);
    }
    
    @objc open var resource: SpineAnimationStateDataBox {
        pResource
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutableRawPointer) -> Void
    ) {
        withUnsafeMutablePointer(to: &self.pSkeletonBox[]) {
            body($0)
        }
    }
    /// Do not modify listener and userData
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutableRawPointer) -> Void
    ) {
        withUnsafeMutablePointer(to: &self.pAnimationStateBox[]) {
            body($0)
        }
    }
    
    @inline(__always)
    public var skeleton: spine.Skeleton {
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
    public var animationState: spine.AnimationState {
        @inline(__always)
        borrowing _modify {
            yield &self.pAnimationStateBox[]
        }
        @inline(__always)
        _read {
            yield self.pAnimationStateBox[]
        }
    }
    
    // @inline(__always)
    // @usableFromInline
    // @nonobjc
    // internal static var _eventDispatcher:spAnimationStateListener {
    //     { state, type, entry, event in
    //         let drawable: SpineSwiftDrawable
    //         #if DEBUG
    //         guard
    //             let userRef = state?.pointee.userData,
    //             let wrapper = Unmanaged<AnyObject>.fromOpaque(userRef).takeUnretainedValue() as? SpineSwiftDrawable
    //         else {
    //             assertionFailure("SpineSwiftDrawable must have userData set to itself")
    //             return
    //         }
    //         drawable = wrapper
    //         #else
    //         drawable = Unmanaged<SpineSwiftDrawable>.fromOpaque(state!.pointee.userData).takeUnretainedValue()
    //         #endif
    //         drawable.dispatch(state: state, type: type, entry: entry, event: event)
    //     }
    // }
    
    // @inline(__always)
    // @usableFromInline
    // @nonobjc
    // internal final func dispatch(
    //     state: UnsafeMutablePointer<spAnimationState>!,
    //     type: spEventType,
    //     entry: UnsafeMutablePointer<spTrackEntry>!,
    //     event: UnsafePointer<spEvent>?
    // ) {
    //     assert(state == &self.pAnimationStateBox[], "state must be the same as self.animationState")
    //     trackMoved(entry: entry, to: type, event: event)
    //     animationListner?.eventDispatched(drawable: self, type: type, entry: entry!, event: event)
    // }
    
    // @objc
    // open func trackMoved(entry: UnsafeMutablePointer<spTrackEntry>, to type:spEventType, event: UnsafePointer<spEvent>?) {

    // }

}
