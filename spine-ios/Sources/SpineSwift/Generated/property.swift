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

/// Property enum
public enum Property: Int32, CaseIterable {
    case rotate = 1
    case x = 2
    case y = 4
    case scaleX = 8
    case scaleY = 16
    case shearX = 32
    case shearY = 64
    case inherit = 128
    case rgb = 256
    case alpha = 512
    case rgb2 = 1024
    case attachment = 2048
    case deform = 4096
    case event = 8192
    case drawOrder = 16384
    case ikConstraint = 32768
    case transformConstraint = 65536
    case pathConstraintPosition = 131072
    case pathConstraintSpacing = 262144
    case pathConstraintMix = 524288
    case physicsConstraintInertia = 1_048_576
    case physicsConstraintStrength = 2_097_152
    case physicsConstraintDamping = 4_194_304
    case physicsConstraintMass = 8_388_608
    case physicsConstraintWind = 16_777_216
    case physicsConstraintGravity = 33_554_432
    case physicsConstraintMix = 67_108_864
    case physicsConstraintReset = 134_217_728
    case sequence = 268_435_456
    case sliderTime = 536_870_912
    case sliderMix = 1_073_741_824

    public static func fromValue(_ value: Int32) -> Property? {
        return Property(rawValue: value)
    }
}
