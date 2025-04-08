//
//  MetalSampler.swift
//  SpineSwift
//
//  Created by 박병관 on 4/7/25.
//

import Foundation
import spine_c
#if canImport(Metal)
import Metal
#endif

public struct AtlasWrap: CustomStringConvertible, RawRepresentable, Hashable, BitwiseCopyable, Sendable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.rawValue)
    }
    
    public var rawValue: spAtlasWrap

    public init(rawValue: spAtlasWrap) {
        self.rawValue = rawValue
    }



    public var description: String {
        switch rawValue {
        case SP_ATLAS_CLAMPTOEDGE: return "ClampToEdge"
        case SP_ATLAS_REPEAT: return "Repeat"
        case SP_ATLAS_MIRROREDREPEAT: return "MirrorRepeat"
        default: return "Unknown"
        }
    }
}

public struct AtlasFilter: CustomStringConvertible,RawRepresentable, Hashable, Sendable, BitwiseCopyable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.rawValue)
    }
    
    public var rawValue: spAtlasFilter
    
    public init(rawValue: spAtlasFilter) {
        self.rawValue = rawValue
    }


    public var description: String {
        switch rawValue {
        case SP_ATLAS_NEAREST: return "Nearest"
        case SP_ATLAS_LINEAR: return "Linear"
        case SP_ATLAS_MIPMAP_LINEAR_LINEAR: return "MipLinearLinear"
        case SP_ATLAS_MIPMAP_NEAREST_NEAREST: return "MipNearestNearest"
        case SP_ATLAS_MIPMAP_LINEAR_NEAREST: return "MipLinearNearest"
        case SP_ATLAS_MIPMAP_NEAREST_LINEAR: return "MipNearestLinear"
        case SP_ATLAS_UNKNOWN_FILTER: return "UnknownFilter"
        default: return "Unknown"
        }
    }
}

public struct AtlasSamplerConfig: Hashable, BitwiseCopyable, Sendable {
    
    public var min: AtlasFilter
    public var mag: AtlasFilter
    public var uwrap: AtlasWrap
    public var vwrap: AtlasWrap

    public init(min: AtlasFilter, mag: AtlasFilter, uwrap: AtlasWrap, vwrap: AtlasWrap) {
        self.min = min
        self.mag = mag
        self.uwrap = uwrap
        self.vwrap = vwrap
    }

}

#if canImport(Metal)

extension AtlasWrap {
    
    public var mtlAddressMode: MTLSamplerAddressMode {
        switch rawValue {
        case SP_ATLAS_CLAMPTOEDGE:
            return .clampToEdge
        case SP_ATLAS_REPEAT:
            return .repeat
        case SP_ATLAS_MIRROREDREPEAT:
            return .mirrorRepeat
        default:
            return .clampToEdge
        }
    }
    
}

extension AtlasFilter {
    
    
    public var minFilter: MTLSamplerMinMagFilter {
        switch rawValue {
        case SP_ATLAS_LINEAR,
             SP_ATLAS_MIPMAP_LINEAR_LINEAR,
             SP_ATLAS_MIPMAP_LINEAR_NEAREST:
            return .linear
        default:
            return .nearest
        }
    }

    public var mipFilter: MTLSamplerMipFilter {
        switch rawValue {
        case SP_ATLAS_MIPMAP_LINEAR_LINEAR,
             SP_ATLAS_MIPMAP_NEAREST_LINEAR:
            return .linear
        case SP_ATLAS_MIPMAP_LINEAR_NEAREST,
             SP_ATLAS_MIPMAP_NEAREST_NEAREST:
            return .nearest
        default:
            return .notMipmapped
        }
    }
    
    public var magFilter: MTLSamplerMinMagFilter {
        switch rawValue {
        case SP_ATLAS_LINEAR:
            return .linear
        default:
            return .nearest
        }
    }
    
}

extension AtlasSamplerConfig {
    
    
    public func generateSamplerDescriptor() -> MTLSamplerDescriptor {
        let descriptor = MTLSamplerDescriptor()
        descriptor.normalizedCoordinates = true
        descriptor.sAddressMode = uwrap.mtlAddressMode
        descriptor.tAddressMode = vwrap.mtlAddressMode
        descriptor.magFilter = mag.magFilter
        descriptor.minFilter = min.minFilter
        descriptor.mipFilter = min.mipFilter
        descriptor.label = "Sampler[min:\(min), mag:\(mag), wrapU:\(uwrap), wrapV:\(vwrap)]"
        return descriptor
    }
    
}



@objcMembers
@available(swift, obsoleted: 1.0)
public final class SpineMetalSamplerConfig: NSObject {
    
    public static func defaultSampleDescriptor(
        min: spAtlasFilter,
        mag: spAtlasFilter,
        uwrap: spAtlasWrap,
        vwrap: spAtlasWrap
    ) -> MTLSamplerDescriptor {
        let config = AtlasSamplerConfig(min: .init(rawValue: min), mag: .init(rawValue: mag), uwrap: .init(rawValue: uwrap), vwrap: .init(rawValue: vwrap))
        return config.generateSamplerDescriptor()
    }
    
    
}

#endif
