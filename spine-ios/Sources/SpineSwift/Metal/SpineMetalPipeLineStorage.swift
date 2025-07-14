//
//  SpineMetalPipeLineStorage.swift
//  spine-ios
//
//  Created by 박병관 on 7/5/25.
//
#if canImport(Metal)
import Metal
import spine_c

public class SpineMetalPipeLineStorage: NSObject {
    
    @inline(__always)
    @usableFromInline
    internal static var caseIterableBlendModes:ContiguousArray<spine_blend_mode> {
        [
            SPINE_BLEND_MODE_NORMAL,
            SPINE_BLEND_MODE_ADDITIVE,
            SPINE_BLEND_MODE_MULTIPLY,
            SPINE_BLEND_MODE_SCREEN,
        ]
    }
    
    @inline(__always)
    @usableFromInline
    internal let storage:ContiguousArray<MTLRenderPipelineState?>
    
    
    @nonobjc
    internal init(storage: ContiguousArray<MTLRenderPipelineState?>) {
        self.storage = storage
    }
    
    @objc public convenience init(device: any MTLDevice, pixelFormat: MTLPixelFormat) throws {
        let bundle: Bundle
        #if SWIFT_PACKAGE // SPM
        bundle = .module
        #else
        bundle = Bundle(for: SpineMetalPipeLineStorage.self)
        #endif
        let defaultLibrary = try device.makeDefaultLibrary(bundle: bundle)
        let blendModes = Self.caseIterableBlendModes
        let descriptor = MTLRenderPipelineDescriptor()
        let constants = MTLFunctionConstantValues()
        var premulAlphaTrue: Bool = true
        constants.setConstantValue(&premulAlphaTrue, type: .bool, withName: "kPremultiplyAlpha")
        let pmaVertex: any MTLFunction = try defaultLibrary.makeFunction(name: "spine_vertexShader", constantValues: constants)
        let pmaFragment = try defaultLibrary.makeFunction(name: "spine_fragmentShader", constantValues: constants)
        premulAlphaTrue = false
        constants.setConstantValue(&premulAlphaTrue, type: .bool, withName: "kPremultiplyAlpha")
        let nonpmaVertex: any MTLFunction = try defaultLibrary.makeFunction(name: "spine_vertexShader", constantValues: constants)
        let nonpmaFragment = try defaultLibrary.makeFunction(name: "spine_fragmentShader", constantValues: constants)
        descriptor.vertexFunction = nonpmaVertex
        descriptor.fragmentFunction = nonpmaFragment
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.vertexBuffers[0].mutability = .immutable
        descriptor.vertexBuffers[1].mutability = .immutable
        descriptor.vertexBuffers[2].mutability = .immutable
        descriptor.fragmentBuffers[0].mutability = .immutable
        var pipelineStates = [ColorBlendPipeLineKey: MTLRenderPipelineState]()
        var pipeLinecache = [Int:MTLRenderPipelineState]()
        var buffer = ContiguousArray<MTLRenderPipelineState?>()
        for blendMode in blendModes {
            var label = ""
            switch blendMode {
            case SPINE_BLEND_MODE_NORMAL:
                label = "SPINE_NORMAL"
            case SPINE_BLEND_MODE_SCREEN:
                label = "SPINE_SCREEN"
            case SPINE_BLEND_MODE_MULTIPLY:
                label = "SPINE_MULTIPLY"
            case SPINE_BLEND_MODE_ADDITIVE:
                label = "SPINE_ADDITIVE"
            default:
                continue
            }
            for pma in [false, true] {
                if (pma) {
                    descriptor.vertexFunction = pmaVertex
                } else {
                    descriptor.vertexFunction = nonpmaVertex
                }
                if  blendMode == SPINE_BLEND_MODE_ADDITIVE || blendMode == SPINE_BLEND_MODE_NORMAL, pma {
                    descriptor.label = label + "_PMA"
                    descriptor.fragmentFunction = pmaFragment
                } else {
                    descriptor.fragmentFunction = nonpmaFragment
                    descriptor.label = label
                }
                descriptor.colorAttachments[0].apply(
                    blendMode: blendMode,
                    with: pma
                )
                let hashCode = descriptor.colorAttachments[0].computeLocalHashCode(pma: pma)
                if let existing = pipeLinecache[hashCode] {
                    pipelineStates[.init(pma: pma, blendMode: blendMode)] = existing
                    buffer.append(existing)
                } else {
                    let newPipeLine = try device.makeRenderPipelineState(descriptor: descriptor)
                    pipeLinecache[hashCode] = newPipeLine
                    pipelineStates[.init(pma: pma, blendMode: blendMode)] = newPipeLine
                    buffer.append(newPipeLine)
                }
            }

        }
        self.init(storage: buffer)
    }
    
    @nonobjc
    public convenience init<E:Error>(
        device: MTLDevice,
        block: (MTLDevice, ColorBlendPipeLineKey) throws(E) -> MTLRenderPipelineState?
    ) throws(E) {
        let blendModes = Self.caseIterableBlendModes
        var buffer = ContiguousArray<MTLRenderPipelineState?>()
        for blendMode in blendModes {
            for pma in [false, true] {
                let state = try (block(device, .init(pma: pma, blendMode: blendMode)))
                buffer.append(state)

            }

        }
        self.init(storage: buffer)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc
    public convenience init(
        device: any MTLDevice,
        block: (MTLDevice, SpineColorBlendBridgedKey, UnsafeMutablePointer<NSError?>) -> MTLRenderPipelineState?
    ) throws {
        let blendModes = Self.caseIterableBlendModes
        var buffer = ContiguousArray<MTLRenderPipelineState?>()
        var error:NSError? = nil
        for blendMode in blendModes {
            for pma in [false, true] {
                let state = (block(device, .init(pma: pma, blendMode: blendMode), &error))
                if let _error = error {
                    throw _error
                }
                buffer.append(state)
            }

        }
        self.init(storage: buffer)
    }
    
    @usableFromInline
    @inline(__always)
    internal func renderPipelineState(
        for blendMode: spine_blend_mode,
        premultiplyAlpha: Bool = true
    ) -> MTLRenderPipelineState? {
        let base = Int(blendMode.rawValue) << 1
        let index = base | (premultiplyAlpha ? 1 : 0)
        guard index < storage.count else {
            return nil
        }
        return storage[index]
    }
    
    @nonobjc
    public func renderPipelineState(_ key: ColorBlendPipeLineKey) -> MTLRenderPipelineState? {
        return renderPipelineState(for: key.blendMode, premultiplyAlpha: key.pma)
    }
    
    @objc(renderPipelineStatefromKey:)
    public func __renderPipelineState(_ key: SpineColorBlendBridgedKey) -> MTLRenderPipelineState? {
        return renderPipelineState(key.imp)
    }
            
    
}


fileprivate extension MTLRenderPipelineColorAttachmentDescriptor {
    
    func computeLocalHashCode(pma:Bool) -> Int {
        var hasher = Hasher()
        hasher.combine(self.sourceRGBBlendFactor)
        hasher.combine(self.sourceAlphaBlendFactor)
        hasher.combine(self.destinationRGBBlendFactor)
        hasher.combine(self.destinationAlphaBlendFactor)
        hasher.combine(pma)
        return hasher.finalize()
    }
    
}

fileprivate extension MTLRenderPipelineColorAttachmentDescriptor {
    
    func apply(blendMode: spine_blend_mode, with premultipliedAlpha: Bool) {
        isBlendingEnabled = true
        sourceRGBBlendFactor = blendMode.sourceRGBBlendFactor(premultipliedAlpha: premultipliedAlpha)
        sourceAlphaBlendFactor = blendMode == SPINE_BLEND_MODE_SCREEN ? .oneMinusDestinationAlpha : .one
        switch blendMode {
        case SPINE_BLEND_MODE_NORMAL, SPINE_BLEND_MODE_MULTIPLY:
            destinationAlphaBlendFactor = .oneMinusSourceAlpha
            destinationRGBBlendFactor = .oneMinusSourceAlpha
        case SPINE_BLEND_MODE_ADDITIVE, SPINE_BLEND_MODE_SCREEN:
            destinationAlphaBlendFactor = .one
            destinationRGBBlendFactor = .one
        default:
            destinationRGBBlendFactor = .one
            destinationAlphaBlendFactor = .one
        }
    }
    
}

fileprivate extension spine_blend_mode {
    
    func sourceRGBBlendFactor(premultipliedAlpha: Bool) -> MTLBlendFactor {
        switch self {
        case SPINE_BLEND_MODE_NORMAL:
            return premultipliedAlpha ? .one : .sourceAlpha
        case SPINE_BLEND_MODE_ADDITIVE:
            return premultipliedAlpha ? .one : .sourceAlpha
        case SPINE_BLEND_MODE_MULTIPLY:
            // requires src rgb chnnel to be multiplied by 1 alpha src before blending in non pma
            return  .destinationColor
        case SPINE_BLEND_MODE_SCREEN:
            // requires src rgb chnnel to be multiplied by 1 alpha src before blending in non pma
            return  .oneMinusDestinationColor
        default:
            return .one // Should never be called
        }
    }

}

#endif
