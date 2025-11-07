//
//  MetalSampler.swift
//  SpineSwift
//
//  Created by 박병관 on 4/7/25.
//

import Foundation
import SpineC
import spine_apple_extension

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

    public var rawValue: spine_texture_wrap

    public init(rawValue: spine_texture_wrap) {
        self.rawValue = rawValue
    }


    public var description: String {

        switch rawValue {
        case SPINE_TEXTURE_WRAP_CLAMP_TO_EDGE: return "ClampToEdge"
        case SPINE_TEXTURE_WRAP_REPEAT: return "Repeat"
        case SPINE_TEXTURE_WRAP_MIRRORED_REPEAT: return "MirrorRepeat"
        default: return "Unknown"
        }
    }
}

public struct AtlasFilter: CustomStringConvertible, RawRepresentable, Hashable, Sendable, BitwiseCopyable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.rawValue)
    }

    public var rawValue: spine_texture_filter

    public init(rawValue: spine_texture_filter) {
        self.rawValue = rawValue
    }


    public var description: String {

        switch rawValue {
        case SPINE_TEXTURE_FILTER_NEAREST: return "Nearest"
        case SPINE_TEXTURE_FILTER_LINEAR: return "Linear"
        case SPINE_TEXTURE_FILTER_MIP_MAP_LINEAR_LINEAR: return "MipLinearLinear"
        case SPINE_TEXTURE_FILTER_MIP_MAP_NEAREST_NEAREST: return "MipNearestNearest"
        case SPINE_TEXTURE_FILTER_MIP_MAP_LINEAR_NEAREST: return "MipLinearNearest"
        case SPINE_TEXTURE_FILTER_MIP_MAP_NEAREST_LINEAR: return "MipNearestLinear"
        case SPINE_TEXTURE_FILTER_UNKNOWN: return "UnknownFilter"
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
            case SPINE_TEXTURE_WRAP_CLAMP_TO_EDGE:
                return .clampToEdge
            case SPINE_TEXTURE_WRAP_REPEAT:
                return .repeat
            case SPINE_TEXTURE_WRAP_MIRRORED_REPEAT:
                return .mirrorRepeat
            default:
                return .clampToEdge
            }
        }

    }

    extension AtlasFilter {


        public var minFilter: MTLSamplerMinMagFilter {
            switch rawValue {
            case SPINE_TEXTURE_FILTER_LINEAR,
                SPINE_TEXTURE_FILTER_MIP_MAP_LINEAR_LINEAR,
                SPINE_TEXTURE_FILTER_MIP_MAP_LINEAR_NEAREST:
                return .linear
            default:
                return .nearest
            }
        }

        public var mipFilter: MTLSamplerMipFilter {
            switch rawValue {
            case SPINE_TEXTURE_FILTER_MIP_MAP_LINEAR_LINEAR,
                SPINE_TEXTURE_FILTER_MIP_MAP_NEAREST_LINEAR:

                return .linear
            case SPINE_TEXTURE_FILTER_MIP_MAP_LINEAR_NEAREST,
                SPINE_TEXTURE_FILTER_MIP_MAP_NEAREST_NEAREST:
                return .nearest

            default:
                return .notMipmapped
            }
        }

        public var magFilter: MTLSamplerMinMagFilter {
            switch rawValue {
            case SPINE_TEXTURE_FILTER_LINEAR:
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
            min: spine_texture_filter,
            mag: spine_texture_filter,
            uwrap: spine_texture_wrap,
            vwrap: spine_texture_wrap
        ) -> MTLSamplerDescriptor {
            let config = AtlasSamplerConfig(
                min: .init(rawValue: min), mag: .init(rawValue: mag), uwrap: .init(rawValue: uwrap), vwrap: .init(rawValue: vwrap))
            return config.generateSamplerDescriptor()
        }


    }

#endif
