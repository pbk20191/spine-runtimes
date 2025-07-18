import Foundation
import SpineShadersStructs
import simd
//
//  CommandEntry.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c

internal struct CommandEntry: Sendable {

    public typealias VertexBuffer = ContiguousArray<SpineAdvancedVertex>


    public var verteArray: VertexBuffer

    public var metaInfo: [CommandMeta]

    //    let sizeInfo:SizeInfo

    internal struct CommandMeta: Hashable, Sendable, BitwiseCopyable {

        public var pageIndex: Int
        public var blendMode: spine_blend_mode
        public var _slice: NSRange

        public var slice: VertexBuffer.Indices {
            get {
                .init(uncheckedBounds: (_slice.lowerBound, _slice.upperBound))
            }
            set {
                self._slice = .init(newValue)
            }
            @storageRestrictions(initializes: _slice)
            init(newValue) {
                self._slice = .init(newValue)
            }
        }
        #if compiler(<6.1)
            func hash(into hasher: inout Hasher) {
                hasher.combine(pageIndex)
                hasher.combine(blendMode.rawValue)
                hasher.combine(slice)
            }

            static func == (lhs: CommandMeta, rhs: CommandMeta) -> Bool {
                guard
                    lhs.pageIndex == rhs.pageIndex,
                    lhs.blendMode == rhs.blendMode,
                    lhs.slice == rhs.slice
                else { return false }
                return true
            }
        #endif

        public init(pageIndex: Int, blendMode: spine_blend_mode, slice: VertexBuffer.Indices) {
            self.pageIndex = pageIndex
            self.blendMode = blendMode
            self.slice = slice
        }

    }

    public init() {
        self.verteArray = []
        self.metaInfo = []
    }

    internal init(_ list: some Sequence<spine_render_command>, _ buffers: UnsafeBufferPointer<spine_atlas_page>) {
        //        self.sizeInfo = sizeInfo
        self.init()
        let vertexBuffer: VertexBuffer

        do {
            var mutableBuffer = VertexBuffer()
            var commandMeta = [CommandMeta]()
            for cmd in list {
                let numvertices = Int(spine_render_command_get_num_vertices(cmd))
                let numIndices = Int(spine_render_command_get_num_indices(cmd))

                let indices = UnsafeBufferPointer(start: spine_render_command_get_indices(cmd), count: Int(numIndices))
                let colors = UnsafeBufferPointer(start: spine_render_command_get_colors(cmd), count: numvertices)
                let darkColors = UnsafeBufferPointer(start: spine_render_command_get_dark_colors(cmd), count: numvertices)
                let uvs = UnsafeBufferPointer(start: spine_render_command_get_uvs(cmd), count: numvertices * 2)
                let positions = UnsafeBufferPointer(start: spine_render_command_get_positions(cmd), count: numvertices * 2)

                //                let numVertices = spineCommand.vertices.count

                //                mutableTextureIndex.append(Int(atlasPage))
                mutableBuffer.reserveCapacity(mutableBuffer.count + indices.count)
                let startIndex = mutableBuffer.endIndex
                defer {
                    let ptr = spine_render_command_get_texture(cmd)
                    let pageIndex =
                        buffers.firstIndex {
                            ptr == spine_atlas_page_get_texture($0)
                        } ?? -1
                    let blendMode = spine_render_command_get_blend_mode(cmd)

                    if let lastMeta = commandMeta.last, lastMeta.pageIndex == pageIndex, lastMeta.blendMode == blendMode,
                        lastMeta.slice.upperBound == startIndex
                    {
                        commandMeta.removeLast()
                        commandMeta.append(
                            .init(pageIndex: pageIndex, blendMode: blendMode, slice: lastMeta.slice.lowerBound..<mutableBuffer.endIndex)
                        )
                    } else {
                        commandMeta.append(
                            .init(
                                pageIndex: pageIndex,
                                blendMode: blendMode,
                                slice: startIndex..<mutableBuffer.endIndex
                            )
                        )
                    }

                }
                indices.forEach {
                    let index = Int($0)

                    let xIndex = 2 * index
                    let yIndex = xIndex + 1

                    let positionX = positions[xIndex]
                    // inverting position is required because of the opengl coordinate system
                    let positionY = positions[yIndex]


                    let vertex = SpineAdvancedVertex(
                        position: SIMD2<Float>(positionX, positionY),
                        uv: [
                            uvs[xIndex],
                            uvs[yIndex],
                        ],
                        color: .init(bitPattern: colors[index]),
                        darkColor: .init(bitPattern: darkColors[index])
                    )
                    mutableBuffer.append(vertex)
                }

            }
            vertexBuffer = mutableBuffer
            self.metaInfo = commandMeta
        }
        self.verteArray = vertexBuffer
    }

}
