//
//  CommandEntry.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c
import SpineShadersStructs

public struct CommandEntry {
    
    public typealias VertexBuffer =  ContiguousArray<SpineVertex>

    
    public let verteArray:VertexBuffer

    public let metaInfo:Array<CommandMeta>

//    let sizeInfo:SizeInfo
    
    public struct CommandMeta {
        
        public let textureId:TextureIdentifier
        public let blendMode:spBlendMode
        public let slice:VertexBuffer.Indices
    }
    
    public init(_ list: [SpineCRenderCommand]) {
        
        let vertexBuffer:VertexBuffer
        
        do {
            var mutableBuffer = VertexBuffer()
            var commandMeta = Array<CommandMeta>()
            for spineCommand in list {
                let atlasPage = TextureIdentifier(name: spineCommand.pageName, index: Int(spineCommand.textureIndex), pma: spineCommand.pma)

                let indices = UnsafeBufferPointer(start: spineCommand.indices, count: Int(spineCommand.indexCount))
                
//                assert(spineCommand.vertices.count == spineCommand.uvs.count)
//                assert(spineCommand.colors.count == spineCommand.uvs.count * 2)
//                assert(spineCommand.uvs.count - 1 == )

//                let numVertices = spineCommand.vertices.count
                let positions = UnsafeBufferPointer(start: spineCommand.positions, count: Int(spineCommand.positionCount))

//                mutableTextureIndex.append(Int(atlasPage))
                let uvs = UnsafeBufferPointer(start: spineCommand.uvs, count: spineCommand.uvCount)
                let colors = UnsafeBufferPointer(start: spineCommand.colors, count: spineCommand.colorCount)
                mutableBuffer.reserveCapacity(mutableBuffer.count + indices.count)
                let startIndex = mutableBuffer.endIndex
                defer {

                    commandMeta.append(
                        .init(
                            textureId: atlasPage,
                            blendMode: spineCommand.blendMode,
                            slice: startIndex..<mutableBuffer.endIndex
                        )
                    )
                }
                positions.withMemoryRebound(to: SIMD2<Float>.self) { postionBuffer in
                    uvs.withMemoryRebound(to: SIMD2<Float>.self) { uvBuffer in
                        indices.forEach{
                            let index = Int($0)


                            let color:SIMD4<Float>
                            
                            do {
                                let code = colors[index]
                                if code != -1 {
                                    let alpha = Float((code >> 24) & 0xFF)
                                    let red = Float((code >> 16) & 0xFF)
                                    let green = Float((code >> 8) & 0xFF)
                                    let blue = Float(code & 0xFF)
                                            
                                    color = [
                                        red / 255,
                                        green / 255,
                                        blue / 255,
                                        alpha / 255
                                    ]
                                } else {
                                    color = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
                                }

                            }
                            let vertex = SpineVertex(
                                position: postionBuffer[index],
                                color: color,
                                uv: uvBuffer[index]
                            )
                            mutableBuffer.append(vertex)
                        }

                    }
                }

            }
            vertexBuffer = mutableBuffer
            self.metaInfo = commandMeta
        }
        self.verteArray = vertexBuffer
    }
    
    public init(_ list: some RandomAccessCollection<RenderCommand>) {
//        self.sizeInfo = sizeInfo
        let vertexBuffer:VertexBuffer
        
        do {
            var mutableBuffer = VertexBuffer()
            var commandMeta = Array<CommandMeta>()
            for spineCommand in list {
                guard let atlasPage = spineCommand.textureId else {
                    continue
                }
                let indices = spineCommand.indices
                
                spineCommand.indices.count
//                assert(spineCommand.vertices.count == spineCommand.uvs.count)
//                assert(spineCommand.colors.count == spineCommand.uvs.count * 2)
//                assert(spineCommand.uvs.count - 1 == )
                if spineCommand.colors.count != spineCommand.uvs.count * 2 {
                    
                }
//                let numVertices = spineCommand.vertices.count
                let positions = spineCommand.vertices

//                mutableTextureIndex.append(Int(atlasPage))
                let uvs = spineCommand.uvs
                let colors = spineCommand.colors
                mutableBuffer.reserveCapacity(mutableBuffer.count + indices.count)
                let startIndex = mutableBuffer.endIndex
                defer {

                    commandMeta.append(
                        .init(
                            textureId: atlasPage,
                            blendMode: spineCommand.blendMode,
                            slice: startIndex..<mutableBuffer.endIndex
                        )
                    )
                }
                indices.forEach{
                    let index = Int($0)
                    
                    let xIndex = 2 * index
                    let yIndex = xIndex + 1
                    
                    let positionX = positions[xIndex]
                    // inverting position is required because of the opengl coordinate system
                    let positionY = positions[yIndex]

                    let color:SIMD4<Float>
                    
                    do {
                        let code = colors[index]
                        if code != -1 {
                            let alpha = Float((code >> 24) & 0xFF)
                            let red = Float((code >> 16) & 0xFF)
                            let green = Float((code >> 8) & 0xFF)
                            let blue = Float(code & 0xFF)
                                    
                            color = [
                                red / 255,
                                green / 255,
                                blue / 255,
                                alpha / 255
                            ]
                        } else {
                            color = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
                        }

                    }
                    let vertex = SpineVertex(
                        position: SIMD2<Float>(positionX, positionY),
                        color: color,
                        uv: [
                            uvs[xIndex],
                            uvs[yIndex],
                        ]
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
