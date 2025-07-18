import Foundation
//
//  ColorBlendPipeLineKey.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c

public struct ColorBlendPipeLineKey: Hashable, BitwiseCopyable, Sendable {

    public var pma: Bool
    public var blendMode: spine_blend_mode

    public init(pma: Bool, blendMode: spine_blend_mode) {
        self.pma = pma
        self.blendMode = blendMode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(pma)
        hasher.combine(blendMode.rawValue)
    }
}

@objcMembers
public final class SpineColorBlendBridgedKey: NSObject, Sendable, NSCopying {

    @nonobjc
    internal let imp: ColorBlendPipeLineKey

    public var pma: Bool { imp.pma }
    public var blendMode: spine_blend_mode { imp.blendMode }

    @nonobjc
    public init(state: ColorBlendPipeLineKey) {
        self.imp = state
    }

    public convenience init(pma: Bool, blendMode: spine_blend_mode) {
        self.init(state: .init(pma: pma, blendMode: blendMode))
    }

    public override func isEqual(_ object: Any?) -> Bool {
        switch object {
        case let ref as SpineColorBlendBridgedKey:
            return ref.imp == imp
        case let value as ColorBlendPipeLineKey:
            return value == imp
        default:
            return false
        }
    }

    public override var hash: Int {
        return imp.hashValue
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        Self.init(state: imp)
    }
}
