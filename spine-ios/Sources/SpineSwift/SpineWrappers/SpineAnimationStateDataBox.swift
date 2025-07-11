//
//  SpineAnimationStateDataBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_cpp
import Foundation

open class SpineAnimationStateDataBox: NSObject {
        
    @usableFromInline
    struct Cleanup: BoxDisposerProtocol {
    
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spine.AnimationStateData>) {
            pointer.deinitialize(count: 1)
            pointer.deallocate()
//            let k = #file as StaticString
//            spine.SpineExtension.free(pointer, #file, #line)
        }
        
    }
    
    @usableFromInline
    typealias Box = PointeeBox<spine.AnimationStateData, Cleanup>
    
    @nonobjc internal let box: Box
    
    @nonobjc
    internal let pSkeletonData: SpineSkeletonDataBox
    @nonobjc
    private var nativePointer: UnsafeMutablePointer<spine.AnimationStateData> {
        self.box._pointer
    }
    
    @nonobjc
    public init(
        skeletonData: SpineSkeletonDataBox,
        animationStateData: UnsafeMutablePointer<spine.AnimationStateData>
    ) {
        precondition(&skeletonData[] == spine_support.animationStateData_getData(&animationStateData.pointee), "skeletonData and animationStateData must be from the same source")
        self.pSkeletonData = skeletonData
        self.box = .init(animationStateData)
        super.init()
    }
    
    @objc
    public convenience init(skeletonData: SpineSkeletonDataBox) {
        let current = #file as StaticString
        let ptr:UnsafeMutablePointer<spine.AnimationStateData> = .allocate(capacity: 1)
        ptr.initialize(to: spine.AnimationStateData(&skeletonData[]))
        self.init(
            skeletonData: skeletonData,
            animationStateData: ptr
        )
    }
    
    @objc
    open var skeletonData: SpineSkeletonDataBox { pSkeletonData }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAnimation(
        _ body: (UnsafeMutableRawPointer) -> Void
    ) {
        
        withUnsafeMutablePointer(to: &self.box[]) {
            body($0)
        }
    }
    
    @inline(__always)
    @nonobjc
    public subscript() -> spine.AnimationStateData {
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
