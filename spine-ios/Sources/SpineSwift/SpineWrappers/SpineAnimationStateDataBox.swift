//
//  SpineAnimationStateDataBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_c
import Foundation

open class SpineAnimationStateDataBox: NSObject {
        
    @nonobjc
    internal let pSkeletonData: SpineSkeletonDataBox
    @nonobjc
    internal let nativePointer: UnsafeMutablePointer<spAnimationStateData>
    
    @nonobjc
    public init(
        skeletonData: SpineSkeletonDataBox,
        animationStateData: UnsafeMutablePointer<spAnimationStateData>
    ) {
        precondition(skeletonData.nativePointer == animationStateData.pointee.skeletonData, "skeletonData and animationStateData must be from the same source")
        self.pSkeletonData = skeletonData
        self.nativePointer = animationStateData
        super.init()
    }
    
    @objc
    public convenience init(skeletonData: SpineSkeletonDataBox) {
        self.init(
            skeletonData: skeletonData,
            animationStateData: spAnimationStateData_create(skeletonData.nativePointer)
        )
    }
    
    deinit {
        spAnimationStateData_dispose(nativePointer)
    }
    
    
    @objc
    open var skeletonData: SpineSkeletonDataBox { pSkeletonData }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutablePointer<spAnimationStateData>) -> Void
    ) {
        body(nativePointer)
    }
    
    @nonobjc
    public subscript() -> spAnimationStateData {
      unsafeAddress {
        UnsafePointer(nativePointer)
      }

      unsafeMutableAddress { nativePointer }
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
