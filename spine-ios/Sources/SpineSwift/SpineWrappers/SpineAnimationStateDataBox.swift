//
//  SpineAnimationStateDataBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_c
import Foundation

open class SpineAnimationStateDataBox: NSObject {
        
    @usableFromInline
    struct Cleanup: BoxDisposerProtocol {
    
        @usableFromInline
        static func dispose(_ pointer: spine_animation_state_data) {
            spine_animation_state_data_dispose(pointer)
        }
        
    }
    
    @usableFromInline
    typealias Box = PointeeBox<spine_animation_state_data_wrapper, Cleanup>
    
    @nonobjc internal let box: Box
    
    @nonobjc
    internal let pSkeletonData: SpineSkeletonDataBox
    @nonobjc
    private var nativePointer: spine_animation_state_data {
        self.box._pointer
    }
    
    @nonobjc
    public init(
        skeletonData: SpineSkeletonDataBox,
        animationStateData: spine_animation_state_data
    ) {
        precondition(&skeletonData[] == spine_animation_state_data_get_skeleton_data(animationStateData), "skeletonData and animationStateData must be from the same source")
        self.pSkeletonData = skeletonData
        self.box = .init(animationStateData)
        super.init()
    }
    
    @objc
    public convenience init(skeletonData: SpineSkeletonDataBox) {
        self.init(
            skeletonData: skeletonData,
            animationStateData: spine_animation_state_data_create(&skeletonData[])
        )
    }
    
    @objc
    open var skeletonData: SpineSkeletonDataBox { pSkeletonData }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (spine_animation_state_data) -> Void
    ) {
        
        withUnsafeMutablePointer(to: &self.box[]) {
            body($0)
        }
    }
    
    @inline(__always)
    @nonobjc
    public subscript() -> spine_animation_state_data_wrapper {
        @inline(__always)
        borrowing _modify {
            yield &box[]
        }
        @inline(__always)
        borrowing _read {
            yield box[]
        }
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return self.nativePointer == other.nativePointer
    }
    
    open override var hash: Int {
        return self.nativePointer.hashValue
    }

}
