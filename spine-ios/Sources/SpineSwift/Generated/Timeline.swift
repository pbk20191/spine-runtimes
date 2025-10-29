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

/// Timeline wrapper
@objc(SpineTimeline)
@objcMembers
open class Timeline: NSObject {
    public let _ptr: UnsafeMutableRawPointer

    public init(fromPointer ptr: spine_timeline) {
        self._ptr = UnsafeMutableRawPointer(ptr)
        super.init()
    }

    public var rtti: Rtti {
        let result = spine_timeline_get_rtti(_ptr.assumingMemoryBound(to: spine_timeline_wrapper.self))
        return Rtti(fromPointer: result!)
    }

    public var frameEntries: Int {
        let result = spine_timeline_get_frame_entries(_ptr.assumingMemoryBound(to: spine_timeline_wrapper.self))
        return result
    }

    public var frameCount: Int {
        let result = spine_timeline_get_frame_count(_ptr.assumingMemoryBound(to: spine_timeline_wrapper.self))
        return result
    }

    public var frames: ArrayFloat {
        let result = spine_timeline_get_frames(_ptr.assumingMemoryBound(to: spine_timeline_wrapper.self))
        return ArrayFloat(fromPointer: result!)
    }

    public var duration: Float {
        let result = spine_timeline_get_duration(_ptr.assumingMemoryBound(to: spine_timeline_wrapper.self))
        return result
    }

    public var propertyIds: ArrayPropertyId {
        let result = spine_timeline_get_property_ids(_ptr.assumingMemoryBound(to: spine_timeline_wrapper.self))
        return ArrayPropertyId(fromPointer: result!)
    }

    /// Sets the value(s) for the specified time.
    ///
    /// - Parameter skeleton: The skeleton the timeline is being applied to. This provides access to the bones, slots, and other skeleton components the timeline may change.
    /// - Parameter lastTime: lastTime The time this timeline was last applied. Timelines such as EventTimeline trigger only at specific times rather than every frame. In that case, the timeline triggers everything between lastTime (exclusive) and time (inclusive).
    /// - Parameter time: The time within the animation. Most timelines find the key before and the key after this time so they can interpolate between the keys.
    /// - Parameter events: If any events are fired, they are added to this array. Can be NULL to ignore firing events or if the timeline does not fire events. May be NULL.
    /// - Parameter alpha: alpha 0 applies the current or setup pose value (depending on pose parameter). 1 applies the timeline value. Between 0 and 1 applies a value between the current or setup pose and the timeline value. By adjusting alpha over time, an animation can be mixed in or out. alpha can also be useful to apply animations on top of each other (layered).
    /// - Parameter blend: Controls how mixing is applied when alpha is than 1.
    /// - Parameter direction: Indicates whether the timeline is mixing in or out. Used by timelines which perform instant transitions such as DrawOrderTimeline and AttachmentTimeline.
    /// - Parameter appliedPose: True to modify the applied pose.
    public func apply(
        _ skeleton: Skeleton, _ lastTime: Float, _ time: Float, _ events: ArrayEvent?, _ alpha: Float, _ blend: MixBlend, _ direction: MixDirection,
        _ appliedPose: Bool
    ) {
        spine_timeline_apply(
            _ptr.assumingMemoryBound(to: spine_timeline_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self), lastTime,
            time, events?._ptr.assumingMemoryBound(to: spine_array_event_wrapper.self), alpha, spine_mix_blend(rawValue: UInt32(blend.rawValue)),
            spine_mix_direction(rawValue: UInt32(direction.rawValue)), appliedPose)
    }

    public static func rttiStatic() -> Rtti {
        let result = spine_timeline_rtti()
        return Rtti(fromPointer: result!)
    }

}
