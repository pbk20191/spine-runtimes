//
//  MetalSampler.swift
//  SpineSwift
//
//  Created by 박병관 on 4/7/25.
//

import Foundation
import spine_cpp
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
    
    public var rawValue: spine.TextureWrap

    public init(rawValue: spine.TextureWrap) {
        self.rawValue = rawValue
    }



    public var description: String {
        
        switch rawValue {
        case spine.TextureWrap_ClampToEdge: return "ClampToEdge"
        case spine.TextureWrap_Repeat: return "Repeat"
        case spine.TextureWrap_MirroredRepeat: return "MirrorRepeat"
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
    
    public var rawValue: spine.TextureFilter
    
    public init(rawValue: spine.TextureFilter) {
        self.rawValue = rawValue
    }


    public var description: String {
        
        switch rawValue {
        case spine.TextureFilter_Nearest: return "Nearest"
        case spine.TextureFilter_Linear: return "Linear"
        case spine.TextureFilter_MipMapLinearLinear: return "MipLinearLinear"
        case spine.TextureFilter_MipMapNearestNearest: return "MipNearestNearest"
        case spine.TextureFilter_MipMapLinearNearest: return "MipLinearNearest"
        case spine.TextureFilter_MipMapNearestLinear: return "MipNearestLinear"
        case spine.TextureFilter_Unknown: return "UnknownFilter"
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
        case spine.TextureWrap_ClampToEdge:
            return .clampToEdge
        case spine.TextureWrap_Repeat:
            return .repeat
        case spine.TextureWrap_MirroredRepeat:
            return .mirrorRepeat
        default:
            return .clampToEdge
        }
    }
    
}

extension AtlasFilter {
    
    
    public var minFilter: MTLSamplerMinMagFilter {
        switch rawValue {
        case spine.TextureFilter_Linear,
             spine.TextureFilter_MipMapLinearLinear,
                spine.TextureFilter_MipMapLinearNearest:
            return .linear
        default:
            return .nearest
        }
    }

    public var mipFilter: MTLSamplerMipFilter {
        switch rawValue {
        case 
        spine.TextureFilter_MipMapLinearLinear,
             spine.TextureFilter_MipMapNearestLinear:

            return .linear
        case spine.TextureFilter_MipMapLinearNearest,
             spine.TextureFilter_MipMapNearestNearest:
            return .nearest

        default:
            return .notMipmapped
        }
    }
    
    public var magFilter: MTLSamplerMinMagFilter {
        switch rawValue {
        case spine.TextureFilter_Linear:
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
        min: spine.TextureFilter,
        mag: spine.TextureFilter,
        uwrap: spine.TextureWrap,
        vwrap: spine.TextureWrap
    ) -> MTLSamplerDescriptor {
        let config = AtlasSamplerConfig(min: .init(rawValue: min), mag: .init(rawValue: mag), uwrap: .init(rawValue: uwrap), vwrap: .init(rawValue: vwrap))
        return config.generateSamplerDescriptor()
    }
    
    
}

#endif
