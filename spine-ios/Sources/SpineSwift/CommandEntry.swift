//
//  CommandEntry.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_cpp
import SpineShadersStructs
import Foundation
import simd

internal struct CommandEntry:  Sendable {
    
    public typealias VertexBuffer =  ContiguousArray<SpineAdvancedVertex>

    
    public var verteArray:VertexBuffer

    public var metaInfo:Array<CommandMeta>

//    let sizeInfo:SizeInfo
    
    internal struct CommandMeta: Hashable, Sendable,BitwiseCopyable {
        
        public var pageIndex:Int
        public var blendMode:spine.BlendMode
        public var _slice:NSRange
        
        public var slice:VertexBuffer.Indices {
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
        
        public init(pageIndex: Int, blendMode: spine.BlendMode, slice: VertexBuffer.Indices) {
            self.pageIndex = pageIndex
            self.blendMode = blendMode
            self.slice = slice
        }
        
    }
    
    public init() {
        self.verteArray = []
        self.metaInfo = []
    }
    
    internal init(_ list: some Sequence<spine.RenderCommand>) {
   //        self.sizeInfo = sizeInfo
        self.init()
           let vertexBuffer:VertexBuffer
           
           do {
               var mutableBuffer = VertexBuffer()
               var commandMeta = Array<CommandMeta>()
               for spineCommand in list {
                   
                   let indices = UnsafeBufferPointer(start: spineCommand.indices, count: Int(spineCommand.numIndices))
                   let colors = UnsafeBufferPointer(start: spineCommand.colors, count: Int(spineCommand.numVertices))
                   let darkColors = UnsafeBufferPointer(start: spineCommand.darkColors, count: Int(spineCommand.numVertices))
                   let uvs = UnsafeBufferPointer(start: spineCommand.uvs, count: Int(spineCommand.numVertices) * 2)
                   let positions = UnsafeBufferPointer(start: spineCommand.positions, count: Int(spineCommand.numVertices) * 2)

   //                let numVertices = spineCommand.vertices.count

   //                mutableTextureIndex.append(Int(atlasPage))
                   mutableBuffer.reserveCapacity(mutableBuffer.count + indices.count)
                   let startIndex = mutableBuffer.endIndex
                   defer {
                       let dict = Unmanaged<NSMutableDictionary>.fromOpaque(spineCommand.texture).takeUnretainedValue()
                       let pageRef = dict["kSpineAtlasPagePointer"] as! NSValue
                       let page = pageRef.pointerValue!.assumingMemoryBound(to: spine.AtlasPage.self)
                       commandMeta.append(
                           .init(
                            pageIndex: Int(page.pointee.index),
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


                       let vertex = SpineAdvancedVertex(
                           position: SIMD2<Float>(positionX, positionY),
                           uv: [
                            uvs[xIndex],
                            uvs[yIndex],
                           ],
                           color: Int32(bitPattern: colors[index]),
                           darkColor: Int32(bitPattern: darkColors[index])
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
