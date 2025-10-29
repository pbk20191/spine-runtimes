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

/// Sequence wrapper
@objc(SpineSequence)
@objcMembers
public class Sequence: NSObject {
    public let _ptr: UnsafeMutableRawPointer

    public init(fromPointer ptr: spine_sequence) {
        self._ptr = UnsafeMutableRawPointer(ptr)
        super.init()
    }

    public convenience init(_ count: Int32) {
        let ptr = spine_sequence_create(count)
        self.init(fromPointer: ptr!)
    }

    /// Returns a unique ID for this attachment.
    public var id: Int32 {
        get {
            let result = spine_sequence_get_id(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
            return result
        }
        set {
            spine_sequence_set_id(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self), newValue)
        }
    }

    public var start: Int32 {
        get {
            let result = spine_sequence_get_start(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
            return result
        }
        set {
            spine_sequence_set_start(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self), newValue)
        }
    }

    public var digits: Int32 {
        get {
            let result = spine_sequence_get_digits(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
            return result
        }
        set {
            spine_sequence_set_digits(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self), newValue)
        }
    }

    /// The index of the region to show for the setup pose.
    public var setupIndex: Int32 {
        get {
            let result = spine_sequence_get_setup_index(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
            return result
        }
        set {
            spine_sequence_set_setup_index(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self), newValue)
        }
    }

    public var regions: ArrayTextureRegion {
        let result = spine_sequence_get_regions(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
        return ArrayTextureRegion(fromPointer: result!)
    }

    public func copyAttachment() -> Sequence {
        let result = spine_sequence_copy(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
        return Sequence(fromPointer: result!)
    }

    public func apply(_ slot: SlotPose?, _ attachment: Attachment?) {
        spine_sequence_apply(
            _ptr.assumingMemoryBound(to: spine_sequence_wrapper.self), slot?._ptr.assumingMemoryBound(to: spine_slot_pose_wrapper.self),
            attachment?._ptr.assumingMemoryBound(to: spine_attachment_wrapper.self))
    }

    public func getPath(_ basePath: String, _ index: Int32) -> String {
        let result = spine_sequence_get_path(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self), basePath, index)
        return String(cString: result!)
    }

    public func dispose() {
        spine_sequence_dispose(_ptr.assumingMemoryBound(to: spine_sequence_wrapper.self))
    }
}
