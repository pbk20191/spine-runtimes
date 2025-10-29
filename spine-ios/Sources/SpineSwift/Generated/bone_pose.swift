//
// Spine Runtimes License Agreement
// Last updated April 5, 2025. Replaces all prior versions.
//
// Copyright (c) 2013-2025, Esoteric Software LLC
//
// Integration of the Spine Runtimes into software or otherwise creating
// derivative works of the Spine Runtimes is permitted under the terms and
// conditions of Section 2 of the Spine Editor License Agreement:
// http://esotericsoftware.com/spine-editor-license
//
// Otherwise, it is permitted to integrate the Spine Runtimes into software
// or otherwise create derivative works of the Spine Runtimes (collectively,
// "Products"), provided that each user of the Products must obtain their own
// Spine Editor license and redistribution of the Products in any form must
// include this license and copyright notice.
//
// THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
// BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

// AUTO GENERATED FILE, DO NOT EDIT.

import Foundation
import SpineC

/// The applied pose for a bone. This is the Bone pose with constraints applied and the world
/// transform computed by Skeleton::updateWorldTransform(Physics).
@objc(SpineBonePose)
@objcMembers
public class BonePose: BoneLocal, Update {
    @nonobjc
    public init(fromPointer ptr: spine_bone_pose) {
        super.init(fromPointer: UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: spine_bone_local_wrapper.self))
    }

    public convenience init() {
        let ptr = spine_bone_pose_create()
        self.init(fromPointer: ptr!)
    }

    public var rtti: Rtti {
        let result = spine_bone_pose_get_rtti(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
        return Rtti(fromPointer: result!)
    }

    /// Part of the world transform matrix for the X axis. If changed, updateLocalTransform() should
    /// be called.
    public var a: Float {
        get {
            let result = spine_bone_pose_get_a(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
            return result
        }
        set {
            spine_bone_pose_set_a(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), newValue)
        }
    }

    /// Part of the world transform matrix for the Y axis. If changed, updateLocalTransform() should
    /// be called.
    public var b: Float {
        get {
            let result = spine_bone_pose_get_b(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
            return result
        }
        set {
            spine_bone_pose_set_b(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), newValue)
        }
    }

    /// Part of the world transform matrix for the X axis. If changed, updateLocalTransform() should
    /// be called.
    public var c: Float {
        get {
            let result = spine_bone_pose_get_c(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
            return result
        }
        set {
            spine_bone_pose_set_c(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), newValue)
        }
    }

    /// Part of the world transform matrix for the Y axis. If changed, updateLocalTransform() should
    /// be called.
    public var d: Float {
        get {
            let result = spine_bone_pose_get_d(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
            return result
        }
        set {
            spine_bone_pose_set_d(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), newValue)
        }
    }

    /// The world X position. If changed, updateLocalTransform() should be called.
    public var worldX: Float {
        get {
            let result = spine_bone_pose_get_world_x(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
            return result
        }
        set {
            spine_bone_pose_set_world_x(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), newValue)
        }
    }

    /// The world Y position. If changed, updateLocalTransform() should be called.
    public var worldY: Float {
        get {
            let result = spine_bone_pose_get_world_y(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
            return result
        }
        set {
            spine_bone_pose_set_world_y(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), newValue)
        }
    }

    /// The world rotation for the X axis, calculated using a and c.
    public var worldRotationX: Float {
        let result = spine_bone_pose_get_world_rotation_x(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
        return result
    }

    /// The world rotation for the Y axis, calculated using b and d.
    public var worldRotationY: Float {
        let result = spine_bone_pose_get_world_rotation_y(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
        return result
    }

    /// The magnitude (always positive) of the world scale X, calculated using a and c.
    public var worldScaleX: Float {
        let result = spine_bone_pose_get_world_scale_x(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
        return result
    }

    /// The magnitude (always positive) of the world scale Y, calculated using b and d.
    public var worldScaleY: Float {
        let result = spine_bone_pose_get_world_scale_y(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
        return result
    }

    /// Called by Skeleton::updateCache() to compute the world transform, if needed.
    public func update(_ skeleton: Skeleton, _ physics: Physics) {
        spine_bone_pose_update(
            _ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self),
            spine_physics(rawValue: UInt32(physics.rawValue)))
    }

    /// Computes the world transform using the parent bone's applied pose and this pose. Child bones
    /// are not updated.
    ///
    /// See World transforms in the Spine Runtimes Guide.
    public func updateWorldTransform(_ skeleton: Skeleton) {
        spine_bone_pose_update_world_transform(
            _ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self))
    }

    /// Computes the local transform values from the world transform.
    ///
    /// If the world transform is modified (by a constraint, rotateWorld(), etc) then this method
    /// should be called so the local transform matches the world transform. The local transform may
    /// be needed by other code (eg to apply another constraint).
    ///
    /// Some information is ambiguous in the world transform, such as -1,-1 scale versus 180
    /// rotation. The local transform after calling this method is equivalent to the local transform
    /// used to compute the world transform, but may not be identical.
    public func updateLocalTransform(_ skeleton: Skeleton) {
        spine_bone_pose_update_local_transform(
            _ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self))
    }

    /// If the world transform has been modified and the local transform no longer matches,
    /// updateLocalTransform() is called.
    public func validateLocalTransform(_ skeleton: Skeleton) {
        spine_bone_pose_validate_local_transform(
            _ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self))
    }

    public func modifyLocal(_ skeleton: Skeleton) {
        spine_bone_pose_modify_local(
            _ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self))
    }

    public func modifyWorld(_ update: Int32) {
        spine_bone_pose_modify_world(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), update)
    }

    public func resetWorld(_ update: Int32) {
        spine_bone_pose_reset_world(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), update)
    }

    /// Transforms a world rotation to a local rotation.
    public func worldToLocalRotation(_ worldRotation: Float) -> Float {
        let result = spine_bone_pose_world_to_local_rotation(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), worldRotation)
        return result
    }

    /// Transforms a local rotation to a world rotation.
    public func localToWorldRotation(_ localRotation: Float) -> Float {
        let result = spine_bone_pose_local_to_world_rotation(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), localRotation)
        return result
    }

    /// Rotates the world transform the specified amount.
    ///
    /// After changes are made to the world transform, updateLocalTransform() should be called on
    /// this bone and any child bones, recursively.
    public func rotateWorld(_ degrees: Float) {
        spine_bone_pose_rotate_world(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self), degrees)
    }

    public static func rttiStatic() -> Rtti {
        let result = spine_bone_pose_rtti()
        return Rtti(fromPointer: result!)
    }

    public override func dispose() {
        spine_bone_pose_dispose(_ptr.assumingMemoryBound(to: spine_bone_pose_wrapper.self))
    }
}
