//
//  File.swift
//  spine-ios
//
//  Created by 박병관 on 3/15/25.
//

import Foundation
import spine_c
import simd

func render(
    _ skeleton: UnsafeMutablePointer<spSkeleton>,
    _ atlas: UnsafeMutablePointer<spAtlas>,
    _ clipping: UnsafeMutablePointer<spSkeletonClipping>
) -> Array<RenderCommand> {
    var bufferList = Array<RenderCommand>()
    
    var color:SIMD4<Float> = [0,0,0,0]
    var r = skeleton.pointee.color.r
    var g = skeleton.pointee.color.g
    var b = skeleton.pointee.color.b
    var a = skeleton.pointee.color.a
    var vertexStart = 0
    var command = RenderCommand()
    
    bufferList.append(command)
    
    let slotBuffer = UnsafeBufferPointer(start: skeleton.pointee.slots, count: Int(skeleton.pointee.slotsCount))

    for slot in slotBuffer {
        guard let slot else {
            continue
        }
        guard let attachment = slot.pointee.attachment else {
            spSkeletonClipping_clipEnd(clipping, slot)
            continue
        }
        if (slot.pointee.color.a == 0 ||  slot.pointee.bone.pointee.active == 0) && !(attachment.pointee.type == SP_ATTACHMENT_CLIPPING) {
            spSkeletonClipping_clipEnd(clipping, slot)
            continue
        }
        var vericesLength = 0
        var vertexSize = 2
        var uvs = [Float]()
        var indices = [Int]()
        if attachment.pointee.type == SP_ATTACHMENT_REGION {
            let regionAttachment = UnsafeMutableRawPointer(attachment).assumingMemoryBound(to: spRegionAttachment.self)
            if regionAttachment.pointee.color.a == 0 {
                spSkeletonClipping_clipEnd(clipping, slot)
                continue
            }
            vericesLength = vertexSize << 2
            if (regionAttachment.pointee.sequence != nil) {
                spSequence_apply(regionAttachment.pointee.sequence, slot, attachment)
            }
            // renderer Specific caching Object
            // which cache MTLTexture in this case
            var atlasPageCache = regionAttachment.rendererObject.pointee.page.rendererObject.mutableCopy() as! [String: AnyHashable]
            //if (command.textureCache.isEmpty && command.blendMode)

        }
        
    }
    
    skeleton.pointee.drawOrder
    
    return bufferList
}
