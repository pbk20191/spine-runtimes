//
//  CommandEntry.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c
import SpineShadersStructs

internal struct CommandEntry {
    
    public typealias VertexBuffer =  ContiguousArray<SpineAdvancedVertex>

    
    public var verteArray:VertexBuffer

    public var metaInfo:Array<CommandMeta>

//    let sizeInfo:SizeInfo
    
    public struct CommandMeta {
        
        public let textureId:TextureIdentifier
        public let blendMode:spBlendMode
        public let slice:VertexBuffer.Indices
    }
    
    public init() {
        self.verteArray = []
        self.metaInfo = []
    }
    
    
    
    
}
