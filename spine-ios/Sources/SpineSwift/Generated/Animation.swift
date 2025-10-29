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

/// Stores a list of timelines to animate a skeleton's pose over time.
@objc(SpineAnimation)
@objcMembers
public class Animation: NSObject {
    public let _ptr: UnsafeMutableRawPointer

    public init(fromPointer ptr: spine_animation) {
        self._ptr = UnsafeMutableRawPointer(ptr)
        super.init()
    }

    public convenience init(_ name: String, _ timelines: ArrayTimeline, _ duration: Float) {
        let ptr = spine_animation_create(name, timelines._ptr.assumingMemoryBound(to: spine_array_timeline_wrapper.self), duration)
        self.init(fromPointer: ptr!)
    }

    /// If the returned array or the timelines it contains are modified, setTimelines() must be
    /// called.
    public var timelines: ArrayTimeline {
        get {
            let result = spine_animation_get_timelines(_ptr.assumingMemoryBound(to: spine_animation_wrapper.self))
            return ArrayTimeline(fromPointer: result!)
        }
        set {
            spine_animation_set_timelines(
                _ptr.assumingMemoryBound(to: spine_animation_wrapper.self), newValue._ptr.assumingMemoryBound(to: spine_array_timeline_wrapper.self))
        }
    }

    /// The duration of the animation in seconds, which is usually the highest time of all frames in
    /// the timeline. The duration is used to know when it has completed and when it should loop
    /// back to the start.
    public var duration: Float {
        get {
            let result = spine_animation_get_duration(_ptr.assumingMemoryBound(to: spine_animation_wrapper.self))
            return result
        }
        set {
            spine_animation_set_duration(_ptr.assumingMemoryBound(to: spine_animation_wrapper.self), newValue)
        }
    }

    /// The animation's name, which is unique across all animations in the skeleton.
    public var name: String {
        let result = spine_animation_get_name(_ptr.assumingMemoryBound(to: spine_animation_wrapper.self))
        return String(cString: result!)
    }

    /// The bone indices affected by this animation.
    public var bones: ArrayInt {
        let result = spine_animation_get_bones(_ptr.assumingMemoryBound(to: spine_animation_wrapper.self))
        return ArrayInt(fromPointer: result!)
    }

    /// Returns true if this animation contains a timeline with any of the specified property IDs.
    public func hasTimeline(_ ids: ArrayPropertyId) -> Bool {
        let result = spine_animation_has_timeline(
            _ptr.assumingMemoryBound(to: spine_animation_wrapper.self), ids._ptr.assumingMemoryBound(to: spine_array_property_id_wrapper.self))
        return result
    }

    /// Applies the animation's timelines to the specified skeleton.
    ///
    /// See Timeline::apply().
    ///
    /// - Parameter skeleton: The skeleton the animation is being applied to. This provides access to the bones, slots, and other skeleton components the timelines may change.
    /// - Parameter lastTime: The last time in seconds this animation was applied. Some timelines trigger only at specific times rather than every frame. Pass -1 the first time an animation is applied to ensure frame 0 is triggered.
    /// - Parameter time: The time in seconds the skeleton is being posed for. Most timelines find the frame before and the frame after this time and interpolate between the frame values. If beyond the getDuration() and loop is true then the animation will repeat, else the last frame will be applied.
    /// - Parameter loop: If true, the animation repeats after the getDuration().
    /// - Parameter events: If any events are fired, they are added to this list. Can be null to ignore fired events or if no timelines fire events.
    /// - Parameter alpha: 0 applies the current or setup values (depending on blend). 1 applies the timeline values. Between 0 and 1 applies values between the current or setup values and the timeline values. By adjusting alpha over time, an animation can be mixed in or out. alpha can also be useful to apply animations on top of each other (layering).
    /// - Parameter blend: Controls how mixing is applied when alpha < 1.
    /// - Parameter direction: Indicates whether the timelines are mixing in or out. Used by timelines which perform instant transitions, such as DrawOrderTimeline or AttachmentTimeline.
    public func apply(
        _ skeleton: Skeleton, _ lastTime: Float, _ time: Float, _ loop: Bool, _ events: ArrayEvent?, _ alpha: Float, _ blend: MixBlend,
        _ direction: MixDirection, _ appliedPose: Bool
    ) {
        spine_animation_apply(
            _ptr.assumingMemoryBound(to: spine_animation_wrapper.self), skeleton._ptr.assumingMemoryBound(to: spine_skeleton_wrapper.self), lastTime,
            time, loop, events?._ptr.assumingMemoryBound(to: spine_array_event_wrapper.self), alpha,
            spine_mix_blend(rawValue: UInt32(blend.rawValue)), spine_mix_direction(rawValue: UInt32(direction.rawValue)), appliedPose)
    }

    /// - Parameter target: After the first and before the last entry.
    public static func search(_ values: ArrayFloat, _ target: Float) -> Int32 {
        let result = spine_animation_search_1(values._ptr.assumingMemoryBound(to: spine_array_float_wrapper.self), target)
        return result
    }

    public static func search2(_ values: ArrayFloat, _ target: Float, _ step: Int32) -> Int32 {
        let result = spine_animation_search_2(values._ptr.assumingMemoryBound(to: spine_array_float_wrapper.self), target, step)
        return result
    }

    public func dispose() {
        spine_animation_dispose(_ptr.assumingMemoryBound(to: spine_animation_wrapper.self))
    }
}
