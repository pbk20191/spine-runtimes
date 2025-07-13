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
import Foundation
import CoreGraphics
import simd
import spine_c

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

        spine_skeleton_set_to_setup_pose(&drawable.skeleton)
        let rect = spine_skeleton_current_rect(&drawable.skeleton, 1)
        return CGRect(
            x: CGFloat(rect.x),
            y: CGFloat(rect.y),
            width: CGFloat(rect.width),
            height: CGFloat(rect.height)
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
        
//         let ptr = drawable.
         
         let oldSkin = spine_skeleton_get_skin(&drawable.skeleton)
         
         let customSkin = spine_skin_create("custom-skin")
         defer {
             spine_skin_dispose(customSkin)
         }
         
         for skinName in skins {
             let skin = withUnsafeMutableBytes(of: &data[]) {
                 spine_skeleton_data_find_skin(.init(OpaquePointer($0.baseAddress!)), skinName)
             }
             if let skin {
                 spine_skin_add_skin(customSkin, skin)
//                 customSkin.addSkin(.init(OpaquePointer(skin)))
             }
//             skinName.unown()
         }
         spine_skeleton_set_skin(&drawable.skeleton, customSkin)
         spine_skeleton_set_to_setup_pose(&drawable.skeleton)
//         spine_skeleton_set_skin(&drawable.skeleton, &customSkin)
//         drawable.skeleton.setSkin(&customSkin)
//         drawable.skeleton.setToSetupPose()
         let animation = animation.flatMap {
             return spine_skeleton_data_find_animation(&data[], $0)
         }
         var bounding = CGRect.null
         if let animation {
             spine_animation_state_set_animation(&drawable.animationState, 0, animation, 0)
//             spine_support.animationState_set(&drawable.animationState, 0, animation, false)
             // spAnimationState_setAnimation(&drawable.animationState, 0, animation, 0)
             let steps = Int(max(Double(spine_animation_get_duration(animation)) / stepTime, 1.0))

             for i in 0..<steps {
                 drawable.update(delta: i > 0 ? Float(stepTime) : 0.0)
                 let rect = spine_skeleton_current_rect(&drawable.skeleton, 1)
                 let sub = CGRect(x: Double(rect.x), y: Double(rect.y), width: Double(rect.width), height: Double(rect.height))
                 if bounding.isNull {
                     bounding = sub
                 } else {
                     bounding = bounding.union(sub)
                 }
             }
         } else {
             let rect = spine_skeleton_current_rect(&drawable.skeleton, 1)
             let sub = CGRect(x: Double(rect.x), y: Double(rect.y), width: Double(rect.width), height: Double(rect.height))
             bounding = sub


         }
         spine_skeleton_set_skin_by_name(&drawable.skeleton, "default")
//         drawable.skeleton.setSkin(.init("default", false, true))
         spine_animation_state_clear_tracks(&drawable.animationState)
//         drawable.animationState.clearTracks()
//         spAnimationState_clearTracks(&drawable.animationState)
        
         if let oldSkin {
             spine_skeleton_set_skin(&drawable.skeleton, oldSkin)
//             drawable.skeleton.setSkin(oldSkin)
//             spSkeleton_setSkin(&drawable.skeleton, oldSkin)
         }
         spine_skeleton_set_to_setup_pose(&drawable.skeleton)
//         drawable.skeleton.setToSetupPose()
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
