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
        static func dispose(_ pointer: UnsafeMutablePointer<spAnimationStateData>) {
            spAnimationStateData_dispose(pointer)
        }
        
    }
    
    @usableFromInline
    typealias Box = PointeeBox<spAnimationStateData, Cleanup>
    
    @nonobjc internal let box: Box
    
    @nonobjc
    internal let pSkeletonData: SpineSkeletonDataBox
    @nonobjc
    private var nativePointer: UnsafeMutablePointer<spAnimationStateData> {
        self.box._pointer
    }
    
    @nonobjc
    public init(
        skeletonData: SpineSkeletonDataBox,
        animationStateData: UnsafeMutablePointer<spAnimationStateData>
    ) {
        precondition(&skeletonData[] == animationStateData.pointee.skeletonData, "skeletonData and animationStateData must be from the same source")
        self.pSkeletonData = skeletonData
        self.box = .init(animationStateData)
        super.init()
    }
    
    @objc
    public convenience init(skeletonData: SpineSkeletonDataBox) {
        self.init(
            skeletonData: skeletonData,
            animationStateData: spAnimationStateData_create(&skeletonData[])
        )
    }
    
    @objc
    open var skeletonData: SpineSkeletonDataBox { pSkeletonData }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutablePointer<spAnimationStateData>) -> Void
    ) {
        
        body(&box[])
    }
    
    @inline(__always)
    @nonobjc
    public subscript() -> spAnimationStateData {
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
