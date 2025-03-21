//
//  BoundsProvider.swift
//  spine-ios
//
//  Created by 박병관 on 3/16/25.
//
import spine_c
import Foundation
import CoreGraphics
import simd

@objc
public protocol SkeletonBoundsProvider {
    func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect
}

@objcMembers
public final class SetupPoseBounds: NSObject, SkeletonBoundsProvider {
    
    public override init() {
        super.init()
    }

    public func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect {
        let region = drawable.accessSkeleton {
            let clipper = spSkeletonClipping_create()!
            defer { spSkeletonClipping_dispose(clipper) }
            return spSkeleton_computeMinMaxRect(&$0, clipper, nil)
        }
        let double_region:SIMD4<Double> = .init(
            SIMD4<Float>(
                region.minX,
                region.minY,
                region.maxX,
                region.maxY
            )
        )
        // 0, 1
        // 2 3
        let origin = double_region.lowHalf
        //0, 2 1 3
        let size = double_region.highHalf - double_region.lowHalf
        
        return CGRect(x: origin.x, y: origin.y, width: size.x, height: size.y)
    }
}

/// A ``BoundsProvider`` that returns fixed bounds.
public final class SpineRawBounds: NSObject, SkeletonBoundsProvider {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    @objc
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        super.init()
    }

    public func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect {
        return CGRectMake(CGFloat(x), CGFloat(y), CGFloat(width), CGFloat(height))
    }
}

/// A ``BoundsProvider`` that calculates the bounding box needed for a combination of skins
/// and an animation.
public final class SkinAndAnimationBounds: NSObject, SkeletonBoundsProvider {
    
    private let animation: String?
    private let skins: [String]
    private let stepTime: TimeInterval;

    /// Constructs a new provider that will use the given `skins` and `animation` to calculate
    /// the bounding box of the skeleton. If no skins are given, the default skin is used.
    /// The `stepTime`, given in seconds, defines at what interval the bounds should be sampled
    /// across the entire animation.
    @objc
    public init(animation: String? = nil, skins: [String]? = nil, stepTime: TimeInterval = 0.1) {
        self.animation = animation
        if let skins, !skins.isEmpty {
            self.skins = skins
        } else {
            self.skins = ["default"]
        }
        self.stepTime = stepTime
        super.init()
    }
    
    public func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect {
        let data = drawable.resource.skeletonData
        let oldSkin = drawable.pSkeleton.pointee.skin
        
        let customSkin = spSkin_create("custom-skin")
        defer {
            spSkin_dispose(customSkin)
        }
        let clipper = spSkeletonClipping_create()
        defer {
            spSkeletonClipping_dispose(clipper)
        }
        for skinName in skins {
            if let skin = spSkeletonData_findSkin(data, skinName) {
                spSkin_addSkin(customSkin, skin)
            }
        }
        spSkeleton_setSkin(drawable.pSkeleton, customSkin);
        spSkeleton_setToSetupPose(drawable.pSkeleton)
        let animation = animation.flatMap {
            spSkeletonData_findAnimation(data, $0)
        }
        var min_simd: SIMD2<Float> = [
            .greatestFiniteMagnitude,
            .greatestFiniteMagnitude
        ]
        var max_simd:SIMD2<Float> = [
            -.greatestFiniteMagnitude,
             -.greatestFiniteMagnitude
        ]

        if let animation {
            spAnimationState_setAnimation(drawable.pAnimationState, 0, animation, 0)
            let steps = Int(max(Double(animation.pointee.duration) / stepTime, 1.0))
            for i in 0..<steps {
                drawable.update(delta: i > 0 ? Float(stepTime) : 0.0)
                let rect = spSkeleton_computeMinMaxRect(drawable.pSkeleton, clipper, nil)
                let bounds:SIMD4<Float> = [
                    rect.minX,
                    rect.minY,
                    rect.maxX,
                    rect.maxY
                    
                ]
                min_simd = min(min_simd, bounds.lowHalf)
                max_simd = max(max_simd, bounds.highHalf)
            }
        } else {
            let rect = spSkeleton_computeMinMaxRect(drawable.pSkeleton, clipper, nil)
            let bounds:SIMD4<Float> = [
                rect.minX,
                rect.minY,
                rect.maxX,
                rect.maxY
                
            ]
            min_simd = bounds.lowHalf
            max_simd = bounds.highHalf
        }
        spSkeleton_setSkinByName(drawable.pSkeleton, "default")
        spAnimationState_clearTracks(drawable.pAnimationState)
        
        if let oldSkin {
            spSkeleton_setSkin(drawable.pSkeleton, oldSkin)
        }
        spSkeleton_setToSetupPose(drawable.pSkeleton)
        drawable.update(delta: 0)
        let double_simd = SIMD4<Double>(lowHalf: .init(min_simd), highHalf: .init(max_simd))
        let origin = SIMD2<Double>(min_simd)
        let size = SIMD2<Double>(max_simd) - origin
        return CGRect(x: origin.x, y: origin.y, width: size.x, height: size.y)
      }
}

/// How a view should be inscribed into another view.
@objc
public enum ContentMode: Int, BitwiseCopyable {
    case fit /// As large as possible while still containing the source view entirely within the target view.
    case fill /// Fill the target view by distorting the source's aspect ratio.
}

/// How a view should aligned withing another view.
@objc
public enum Alignment: Int, BitwiseCopyable {
    case topLeft
    case topCenter
    case topRight
    case centerLeft
    case center
    case centerRight
    case bottomLeft
    case bottomCenter
    case bottomRight
    
    internal var x: CGFloat {
        switch self {
        case .topLeft, .centerLeft, .bottomLeft: return -1.0
        case .topCenter, .center, .bottomCenter: return 0.0
        case .topRight, .centerRight, .bottomRight: return 1.0
        }
    }
    
    internal var y: CGFloat {
        switch self {
        case .topLeft, .topCenter, .topRight: return -1.0
        case .centerLeft, .center, .centerRight: return 0.0
        case .bottomLeft, .bottomCenter, .bottomRight: return 1.0
        }
    }
}
