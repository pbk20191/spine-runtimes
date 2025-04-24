//
//  File.swift
//  spine-ios
//
//  Created by 박병관 on 4/20/25.
//

import Foundation
import spine_c
import SpineShadersStructs

internal struct RenderCallBackContext {
    
    
    var dictionary = [UnsafeMutablePointer<spAtlasPage>: Int]()
    var commandEntry = CommandEntry()
    var atlas:UnsafePointer<spAtlas>
    
    static func render(
        _ atlas:UnsafePointer<spAtlas>,
        _ skeleton:UnsafeMutablePointer<spSkeleton>,
        _ clipper: UnsafeMutablePointer<spSkeletonClipping>
    ) -> CommandEntry {
        var cb = RenderCallBackContext(atlas: atlas)
        var count = 0
        for page in sequence(first: atlas.pointee.pages, next: \.pointee.next) {
            cb.dictionary[page] = count
            count += 1
        }
        withUnsafeMutablePointer(to: &cb) {
            spSkeleton_render(skeleton,  clipper, fill_render_command_to_entry, $0)
        }
        return cb.commandEntry
    }
}



fileprivate func fill_render_command_to_entry(
    _ cmd: UnsafePointer<SpineRenderCommandBlock>,
    _ ptr:UnsafeMutableRawPointer?
) {
    let contextBuffer = UnsafeMutablePointer<RenderCallBackContext>.init(.init(ptr!))
    let indexBuffer = UnsafeBufferPointer(start: cmd.pointee.indices, count: cmd.pointee.indexCount)
    var context:RenderCallBackContext {
        unsafeAddress { UnsafePointer(contextBuffer) }
        unsafeMutableAddress { contextBuffer }
    }

    let texture = cmd.pointee.renderer.assumingMemoryBound(to: spAtlasRegion.self)
    precondition(texture.pointee.page.pointee.atlas == context.atlas)
    
    let pma = texture.pointee.page.pointee.pma != 0
    let blendMode = cmd.pointee.blendMode
    let color:Int32
    let darkColor:Int32
    do {
        let skeletonColor = cmd.pointee.slot.pointee.bone.pointee.skeleton.pointee.color
        let slotColor = cmd.pointee.slot.pointee.color
        let slotDark = cmd.pointee.slot.pointee.darkColor?.pointee
        let attachmentColor = if cmd.pointee.slot.pointee.attachment.pointee.type == SP_ATTACHMENT_MESH {
            UnsafePointer<spMeshAttachment>(OpaquePointer(cmd.pointee.slot.pointee.attachment))!.pointee.color
        } else if cmd.pointee.slot.pointee.attachment.pointee.type == SP_ATTACHMENT_REGION {
            UnsafePointer<spRegionAttachment>(OpaquePointer(cmd.pointee.slot.pointee.attachment))!.pointee.color
        } else {
            spColor(r: 0, g: 0, b: 0, a: 0)
        }
        let fa = skeletonColor.a * slotColor.a * attachmentColor.a
        let a:UInt32 = UInt32(UInt8(fa * 255))
        let fr = (skeletonColor.r * slotColor.r * attachmentColor.r)
        let fg = (skeletonColor.g * slotColor.g * attachmentColor.g)
        let fb = (skeletonColor.b * slotColor.b * attachmentColor.b)
        
        if (pma) {
            let r:UInt32 = UInt32(UInt8(fr * fa * 255))
            let g = UInt32(UInt8(fg * fa * 255))
            let b = UInt32(UInt8(fb * fa * 255))
            color = .init(bitPattern: a << 24 | r << 16 | g << 8 | b)
        } else {
            let r:UInt32 = UInt32(UInt8(fr * 255))
            let g = UInt32(UInt8(fg * 255))
            let b = UInt32(UInt8(fb * 255))
            color = .init(bitPattern: a << 24 | r << 16 | g << 8 | b)
        }
        if let slotDark {
            let dr = UInt32(UInt8(slotDark.r * (pma ? fa : 1) * 255))
            let dg = UInt32(UInt8(slotDark.g * (pma ? fa : 1) * 255))

            let db = UInt32(UInt8(slotDark.b * (pma ? fa : 1) * 255))
            let da = UInt32(UInt8((pma ? 1 : 0) * 255))
            darkColor = Int32(bitPattern: da << 24 | dr << 16 | dg << 8 | db)
        } else {
            darkColor = Int32(bitPattern:  0xff000000)
        }
    }
    let pageIndex:Int = context.dictionary[texture.pointee.page, default: -1]
    context.commandEntry.verteArray.reserveCapacity(context.commandEntry.verteArray.count + indexBuffer.count)
    UnsafeBufferPointer(start: cmd.pointee.uvs, count: cmd.pointee.uvCount).withMemoryRebound(to: SIMD2<Float>.self) { uvBuffer in
        UnsafeBufferPointer(start: cmd.pointee.positions, count: cmd.pointee.positionCount).withMemoryRebound(to: SIMD2<Float>.self) { vertexBuffer in
            let startIndex = context.commandEntry.verteArray.endIndex

            for shortIndex in indexBuffer {
                let index = Int(shortIndex)
                let vertex = SpineAdvancedVertex(
                    position: vertexBuffer[index],
                    uv: uvBuffer[index],
                    color: color,
                    darkColor: darkColor
                )
                context.commandEntry.verteArray.append(vertex)
            }
            if let last = context.commandEntry.metaInfo.last, blendMode == last.blendMode, pageIndex == last.pageIndex, last.slice.upperBound == startIndex {
                let metaInfo = CommandEntry.CommandMeta(pageIndex: pageIndex, blendMode: blendMode, slice: last.slice.lowerBound..<context.commandEntry.verteArray.endIndex)
                context.commandEntry.metaInfo.removeLast()
                context.commandEntry.metaInfo.append(metaInfo)
            } else {
                context.commandEntry.metaInfo.append(
                    .init(pageIndex: pageIndex, blendMode: blendMode, slice: startIndex..<context.commandEntry.verteArray.endIndex)
                )
            }
            
            
        }
    }

}

