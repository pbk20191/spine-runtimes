//
//  ColorBlendPipeLineKey.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c
import Foundation

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

@objcMembers
public final class SpineColorBlendBridgedKey: NSObject, Sendable {
    
    public let pma:Bool
    public let blendMode:spBlendMode
    
    public init(pma: Bool, blendMode: spBlendMode) {
        self.pma = pma
        self.blendMode = blendMode
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        switch object {
        case let ref as SpineColorBlendBridgedKey:
            return ref.pma == pma && ref.blendMode == blendMode
        case let value as ColorBlendPipeLineKey:
            return value.pma == pma && value.blendMode == blendMode
        default:
            return false
        }
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(pma)
        hasher.combine(blendMode.rawValue)
        return hasher.finalize()
    }
}
