//
//  ColorBlendPipeLineKey.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c

public struct ColorBlendPipeLineKey: Hashable, BitwiseCopyable {
    
    public var pma:Bool
    public var blendMode:spBlendMode
    
    public init(pma: Bool, blendMode: spBlendMode) {
        self.pma = pma
        self.blendMode = blendMode
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pma)
        hasher.combine(blendMode.rawValue)
    }
}
