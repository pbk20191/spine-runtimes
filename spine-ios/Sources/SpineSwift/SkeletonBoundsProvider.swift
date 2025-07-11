//
//  SkeletonBoundsProvider.swift
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//


//
//  BoundsProvider.swift
//  spine-ios
//
//  Created by 박병관 on 3/16/25.
//
import spine_cpp
import Foundation
import CoreGraphics
import simd

@objc
public protocol SkeletonBoundsProvider {
    func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect
}

@objcMembers
public final class SetupPoseBounds: NSObject, SkeletonBoundsProvider, Sendable {
    
    public override init() {
        super.init()
    }

    public func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect {
        var x = 0 as Float
        var y = 0 as Float
        var width = 0 as Float
        var height = 0 as Float
        var vector = spine_support.SpineFloatVector()
        var clipper = spine.SkeletonClipping()
        drawable.skeleton.setToSetupPose()
        drawable.skeleton.getBounds(
            &x, &y, &width, &height, &vector, &clipper
        )
        return CGRect(
            x: CGFloat(x),
            y: CGFloat(y),
            width: CGFloat(width),
            height: CGFloat(height)
        )
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        object is Self
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(ObjectIdentifier(Self.self))
        hasher.combine(100)
        return hasher.finalize()
    }
    
}

/// A ``BoundsProvider`` that returns fixed bounds.
@objcMembers
public final class SpineRawBounds: NSObject, SkeletonBoundsProvider, Sendable {
    public var x: Double { imp.x }
    public var y: Double { imp.y }
    public var width: Double { imp.z }
    public var height: Double { imp.w }
    
    @nonobjc
    private let imp:SIMD4<Double>

    @nonobjc
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.imp = [x, y, width, height]
    }
    
    @objc(initWithX: y: width: height:)
    @available(swift ,obsoleted: 1.0)
    public convenience init(notForSwift x: Double, y: Double, width: Double, height: Double) {
        self.init(x: x, y: y, width: width, height: height)
    }

    public func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect {
        return CGRectMake(CGFloat(x), CGFloat(y), CGFloat(width), CGFloat(height))
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let a = object as? Self {
            return a.imp == imp
        }
        return false
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(ObjectIdentifier(Self.self))
        hasher.combine(imp)
        return hasher.finalize()
    }
    
    
}

/// A ``BoundsProvider`` that calculates the bounding box needed for a combination of skins
/// and an animation.
 @objc
 public final class SkinAndAnimationBounds: NSObject, SkeletonBoundsProvider, Sendable {
    
     private let animation: String?
     private let skins: [String]
     private let stepTime: TimeInterval;

     /// Constructs a new provider that will use the given `skins` and `animation` to calculate
     /// the bounding box of the skeleton. If no skins are given, the default skin is used.
     /// The `stepTime`, given in seconds, defines at what interval the bounds should be sampled
     /// across the entire animation.
     @nonobjc
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
    
     @available(swift ,obsoleted: 1.0)
     @objc(initWithAnimation:skins:stepTime:)
     public convenience init(
         notForSwift animation: String? = nil, skins: [String]? = nil, stepTime: TimeInterval
     ) {
         self.init(animation: animation, skins: skins, stepTime: stepTime)
     }

    
     public func computeBounds(for drawable: SpineSwiftDrawable) -> CGRect {
         let data = drawable.resource.skeletonData
         let oldSkin = spine_support.skeleton_getSkin(&drawable.skeleton)
         
         var customSkin = spine.Skin(spine.String("custom-skin", false, true))
         var clipper = spine.SkeletonClipping()

         for skinName in skins {
             var skinName = spine.String(skinName, true, false)
             if let skin = spine_support.SkeletonData_findSkin(&data[], skinName) {
                 customSkin.addSkin(skin)
             }
             skinName.unown()
         }
         
         drawable.skeleton.setSkin(&customSkin)
         drawable.skeleton.setToSetupPose()
         let animation = animation.flatMap {
             var skinName = spine.String($0, true, false)
             defer {
                 skinName.unown()
             }
             return spine_support.SkeletonData_findAnimation(&data[], skinName)
         }
         var bounding = CGRect.null
         var x = 0 as Float
         var y = 0 as Float
         var width = 0 as Float
         var height = 0 as Float
         var vertex = spine_support.SpineFloatVector()
         if let animation {
             spine_support.animationState_set(&drawable.animationState, 0, animation, false)
             // spAnimationState_setAnimation(&drawable.animationState, 0, animation, 0)
             let steps = Int(max(Double(animation.pointee.getDuration()) / stepTime, 1.0))

             for i in 0..<steps {
                 drawable.update(delta: i > 0 ? Float(stepTime) : 0.0)
                 drawable.skeleton.getBounds(&x, &y, &width, &height, &vertex, &clipper)
                 let sub = CGRect(x: Double(x), y: Double(y), width: Double(width), height: Double(height))
                 if bounding.isNull {
                     bounding = sub
                 } else {
                     bounding = bounding.union(sub)
                 }
             }
         } else {

             drawable.skeleton.getBounds(&x, &y, &width, &height, &vertex, &clipper)
             let sub = CGRect(x: Double(x), y: Double(y), width: Double(width), height: Double(height))
             bounding = sub


         }
         drawable.skeleton.setSkin(.init("default", false, true))
         drawable.animationState.clearTracks()
//         spAnimationState_clearTracks(&drawable.animationState)
        
         if let oldSkin {
             drawable.skeleton.setSkin(oldSkin)
//             spSkeleton_setSkin(&drawable.skeleton, oldSkin)
         }
         drawable.skeleton.setToSetupPose()
         drawable.update(delta: 0)
         if bounding.isNull {
             return .zero
         }
         return bounding
       }
    
     public override var hash: Int {
         var hasher = Hasher()
         hasher.combine(ObjectIdentifier(Self.self))
         hasher.combine(animation)
         hasher.combine(skins)
         hasher.combine(stepTime)
         return hasher.finalize()
     }
    
     public override func isEqual(_ object: Any?) -> Bool {
         guard
             let other = object as? Self,
             animation == other.animation,
             skins == other.skins,
             stepTime == other.stepTime
         else { return false }
         return true
     }
 }

/// How a view should be inscribed into another view.
@objc
public enum ContentMode: Int, BitwiseCopyable, Sendable {
    case fit /// As large as possible while still containing the source view entirely within the target view.
    case fill /// Fill the target view by distorting the source's aspect ratio.
    case aspectFill /// The option to scale the content to fill the size of the view. Some portion of the content may be clipped to fill the bounds
}

/// How a view should aligned withing another view.
@objc
public enum Alignment: Int, BitwiseCopyable, Sendable {
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
