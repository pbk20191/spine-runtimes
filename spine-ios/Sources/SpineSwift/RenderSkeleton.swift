//
//  RenderSkeleton.swift
//  spine-ios
//
//  Created by 박병관 on 3/15/25.
//

import Foundation
import spine_c
import simd

func renderSkeleton(
    _ skeleton: UnsafeMutablePointer<spSkeleton>,
    _ clipping: UnsafeMutablePointer<spSkeletonClipping>
) -> ContiguousArray<RenderCommand> {
    var commandList = ContiguousArray<RenderCommand>()

    let r = skeleton.pointee.color.r
    let g = skeleton.pointee.color.g
    let b = skeleton.pointee.color.b
    let a = skeleton.pointee.color.a
    var vertexStart = 0
    var commandIndex = 0
    var command :RenderCommand {
        get {
            commandList[commandIndex]
        }
        set {
            commandList[commandIndex] = newValue
        }
        _modify {
            yield &commandList[commandIndex]
        }
    }
    var color = spColor()
    var atlasLookupCache = [
        UnsafePointer<spAtlas>: Array<UnsafeMutablePointer<spAtlasPage>>
        ]()
    commandList.append(RenderCommand(default: ()))

    let slotBuffer = UnsafeBufferPointer(start: skeleton.pointee.slots, count: Int(skeleton.pointee.slotsCount))
    let quadTriangles:[UInt16]  = [0, 1, 2, 2, 3, 0]
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
        var verticesLength = 0
        let vertexSize = 2
        var uvs:[Float]! = nil
        var indices: [UInt16]! = nil
        var atlas: spAtlasRegion? = nil
        
        if attachment.pointee.type == SP_ATTACHMENT_REGION {
            let regionAttachment = UnsafeMutableRawPointer(attachment).assumingMemoryBound(to: spRegionAttachment.self)
            if regionAttachment.pointee.color.a == 0 {
                spSkeletonClipping_clipEnd(clipping, slot)
                continue
            }
            verticesLength = vertexSize << 2
            let atlasPage = regionAttachment.rendererObject.pointee.page!
            if atlasLookupCache[atlasPage.pointee.atlas] == nil {
                atlasLookupCache[atlasPage.pointee.atlas] = sequence(first: atlasPage.pointee.atlas.pointee.pages, next: \.pointee.next)
                    .compactMap(\.self)
            }
            
            let textureId:TextureIdentifier? = if
                let pageName = String(cString: atlasPage.pointee.name, encoding: .utf8),
                let pageIndex = atlasLookupCache[atlasPage.pointee.atlas]?.firstIndex(of: atlasPage)
            {
                .init(name: pageName, index: pageIndex, pma: atlasPage.pointee.pma != 0)
            } else {
                nil
            }
            
            atlas = regionAttachment.rendererObject.pointee
            let blendMode = slot.pointee.data.pointee.blendMode
            if (command.blendMode == nil && command.textureId == nil) {
                command.blendMode = blendMode;
                command.textureId = textureId;
            }

            if (command.blendMode != blendMode || command.textureId != textureId
                || command.vertices.count + verticesLength > 64000
            ) {
                commandList.append(RenderCommand(default: ()))
                commandIndex += 1
                vertexStart = 0;
                command.blendMode = blendMode;
                command.textureId = textureId;
            }
            command.vertices.append(contentsOf: repeatElement(0, count: verticesLength))
            command.vertices.withUnsafeMutableBufferPointer {
                spRegionAttachment_computeWorldVertices(regionAttachment, slot, $0.baseAddress, Int32(vertexStart), Int32(vertexSize))
            }
            withUnsafeBytes(of: regionAttachment.pointee.uvs) {
                let buffer = $0.assumingMemoryBound(to: Float.self)
                uvs = .init(buffer)
            }
            indices = quadTriangles;
            color = regionAttachment.pointee.color
        } else if attachment.pointee.type == SP_ATTACHMENT_MESH {
            let meshAttachment = UnsafeMutableRawPointer(attachment).assumingMemoryBound(to: spMeshAttachment.self)
            

            verticesLength = Int(meshAttachment.pointee.super.worldVerticesLength)
            let blendMode = slot.pointee.data.pointee.blendMode
            atlas = meshAttachment.rendererObject.pointee

            let atlasPage = meshAttachment.rendererObject.pointee.page!
            if atlasLookupCache[atlasPage.pointee.atlas] == nil {
                atlasLookupCache[atlasPage.pointee.atlas] = sequence(first: atlasPage.pointee.atlas.pointee.pages, next: \.pointee.next)
                    .compactMap(\.self)
            }
            
            let textureId:TextureIdentifier? = if
                let pageName = String(cString: atlasPage.pointee.name, encoding: .utf8),
                let pageIndex = atlasLookupCache[atlasPage.pointee.atlas]?.firstIndex(of: atlasPage)
            {
                .init(name: pageName, index: pageIndex, pma: atlasPage.pointee.pma != 0)
            } else {
                nil
            }
            
            if (command.blendMode == nil && command.textureId == nil) {
                command.blendMode = blendMode;
                command.textureId = textureId;
            }

            if (command.blendMode != blendMode || command.textureId != textureId
                || command.vertices.count + verticesLength > 64000
            ) {
                commandList.append(RenderCommand(default: ()))
                commandIndex += 1
                vertexStart = 0;
                command.blendMode = blendMode;
                command.textureId = textureId;
            }
            command.vertices.append(contentsOf: repeatElement(0, count: verticesLength))
            command.vertices.withUnsafeMutableBufferPointer {
                spVertexAttachment_computeWorldVertices(&meshAttachment.pointee.super, slot, 0, Int32(verticesLength), $0.baseAddress, Int32(vertexStart), Int32(vertexSize))
            }
            let triangleBuffer = UnsafeBufferPointer(
                start: meshAttachment.pointee.triangles,
                count: Int(meshAttachment.pointee.trianglesCount)
            )
        
            let uvBuffer = UnsafeBufferPointer(
                start: meshAttachment.pointee.uvs,
                count: verticesLength
            )
            uvs = .init(uvBuffer)
            indices = .init(triangleBuffer)
            color = meshAttachment.pointee.color
            
        } else if attachment.pointee.type == SP_ATTACHMENT_CLIPPING {
            let clipplingAttachment = UnsafeMutableRawPointer(attachment).assumingMemoryBound(to: spClippingAttachment.self)
            spSkeletonClipping_clipStart(clipping, slot, clipplingAttachment)
            continue
        } else {
            continue
        }
        let slotColor = slot.pointee.color
        let alpha = UInt32(UInt8(a * slotColor.a * color.a * 255)) << 24
        let red = UInt32(UInt8(r * slotColor.r * color.r * 255)) << 16
        let blue = UInt32(UInt8(b * slotColor.b * color.b * 255))
        let green = UInt32(UInt8(g * slotColor.g * color.g * 255)) << 8
        let c = alpha | red | blue | green
        let indicesStart = command.indices.count
        var indicesLength = indices.count

        if spSkeletonClipping_isClipping(clipping) != 0 {
            command.vertices.withUnsafeMutableBufferPointer { verticesBuffer in
                command.indices.withUnsafeMutableBufferPointer { indicesBuffer in
                    uvs.withUnsafeMutableBufferPointer { uvBuffer in
                        spSkeletonClipping_clipTriangles(clipping, verticesBuffer.baseAddress!, Int32(vertexStart), indicesBuffer.baseAddress!, Int32(indicesLength), uvBuffer.baseAddress, 2)
                    }

                }
            }
            let clippedVerticesBuffer = UnsafeBufferPointer(
                start: clipping.pointee.clippedVertices.pointee.items,
                count: .init(clipping.pointee.clippedVertices.pointee.size)
            )
            let partitionUVS = UnsafeBufferPointer(
                start: clipping.pointee.clippedUVs.pointee.items,
                count: Int(clipping.pointee.clippedUVs.pointee.size)
            )
            let indicesBuffer = UnsafeBufferPointer(
                start: clipping.pointee.clippedTriangles.pointee.items,
                count: Int(clipping.pointee.clippedTriangles.pointee.size)
            )
            command.vertices.replaceSubrange(vertexStart..., with: clippedVerticesBuffer)
            command.uvs.append(contentsOf: partitionUVS)
            command.indices.append(contentsOf: indicesBuffer)
            verticesLength = clippedVerticesBuffer.count
            indicesLength = Int(clipping.pointee.clippedTriangles.pointee.size)
        } else {
            command.uvs.append(contentsOf: uvs)
            command.indices.append(contentsOf: indices)
        }
        do {
            var targetCount = command.colors.count + (verticesLength << 1)
            var diff = targetCount - command.colors.count
            if diff > 0 {
                command.colors.append(contentsOf: repeatElement(0, count: diff))
            }
        }
        for i in stride(from: vertexStart >> 1, to: (vertexStart >> 1) + (verticesLength >> 1), by: 1) {
            command.colors[i] = Int32(bitPattern: c)
        }
        let firstIndex = UInt16(vertexStart >> 1)
        for i in stride(from: indicesStart, to: indicesStart + indicesLength, by: 1) {
            command.indices[i] += firstIndex
        }
        vertexStart += verticesLength
        spSkeletonClipping_clipEnd(clipping, slot)
    }
    spSkeletonClipping_clipEnd2(clipping)
    if commandList.count == 1, commandList[0].vertices.count == 0 {
        commandList = []
    }
    return commandList
}
