//
//  RenderCommand.swift
//  spine-ios
//
//  Created by 박병관 on 3/15/25.
//
import spine_c
import Foundation

public struct RenderCommand : Hashable  {
    
    
    public var vertices: [Float] = []
    public var uvs: [Float] = []
    public var colors: [Int32] = []
    public var indices: [UInt16] = []
    public var blendMode: spBlendMode! = nil
    public var textureId: TextureIdentifier?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(vertices)
        hasher.combine(uvs)
        hasher.combine(colors)
        hasher.combine(indices)
        hasher.combine(blendMode?.rawValue)
        hasher.combine(textureId)
        
    }
    
    public init(vertices: [Float] = [], uvs: [Float] = [], colors: [Int32] = [], indices: [UInt16] = [], blendMode: spBlendMode! = nil, textureId: TextureIdentifier? = nil) {
        self.vertices = vertices
        self.uvs = uvs
        self.colors = colors
        self.indices = indices
        self.blendMode = blendMode
        self.textureId = textureId
    }
    
    internal init(default:()) {
        self.init()
        colors.reserveCapacity(32)
        uvs.reserveCapacity(32)
        indices.reserveCapacity(32)
        vertices.reserveCapacity(32)
    }

}

public struct TextureIdentifier: Hashable {
    
    public var name:String
    public var index:Int
    public var pma:Bool
    
    public init(name: String, index: Int, pma: Bool) {
        self.name = name
        self.index = index
        self.pma = pma
    }
    
}
