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

public extension SpineAnimationStateDataBox {
    func accessAnimation<R:~Copyable, Failure:Error>(
        _ body: (borrowing PointeeBox<spAnimationStateData>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(.init(native))
    }
    
}
