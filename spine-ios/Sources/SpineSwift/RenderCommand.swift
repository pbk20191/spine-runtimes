//
//  RenderCommand.swift
//  spine-ios
//
//  Created by 박병관 on 3/15/25.
//
import spine_c
import Foundation

public struct RenderCommand : Hashable  {
    
    
    var vertices: [Float] = .init(repeating: 0, count: 32)
    var uvs: [Float] = .init(repeating: 0, count: 32)
    var colors: [Int] = .init(repeating: 0, count: 32)
    var indices: [Int] = .init(repeating: 0, count: 32)
    var blendMode: spBlendMode = SP_BLEND_MODE_NORMAL
    var textureCache: [String:AnyHashable] = [:]
    


    public func hash(into hasher: inout Hasher) {
        hasher.combine(vertices)
        hasher.combine(uvs)
        hasher.combine(colors)
        hasher.combine(indices)
        hasher.combine(blendMode.rawValue)
        hasher.combine(textureCache)
    }

}
