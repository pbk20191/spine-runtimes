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
    
    //    var device: any MTLDevice
    
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
        let blendModes = [
            SP_BLEND_MODE_NORMAL,
            SP_BLEND_MODE_ADDITIVE,
            SP_BLEND_MODE_MULTIPLY,
            SP_BLEND_MODE_SCREEN
        ]
        let descriptor = MTLRenderPipelineDescriptor()
        let constants = MTLFunctionConstantValues()
        var premulAlphaTrue: Bool = true
        constants.setConstantValue(&premulAlphaTrue, type: .bool, withName: "kPremultiplyAlpha")
        let pmaFragment = try defaultLibrary.makeFunction(name: "spine_fragmentShader", constantValues: constants)
        premulAlphaTrue = false
        constants.setConstantValue(&premulAlphaTrue, type: .bool, withName: "kPremultiplyAlpha")
        let nonpmaFragment = try defaultLibrary.makeFunction(name: "spine_fragmentShader", constantValues: constants)
        descriptor.vertexFunction = defaultLibrary.makeFunction(name: "spine_vertexShader")
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
            case SP_BLEND_MODE_NORMAL:
                label = "SPINE_NORMAL"
            case SP_BLEND_MODE_SCREEN:
                label = "SPINE_SCREEN"
            case SP_BLEND_MODE_MULTIPLY:
                label = "SPINE_MULTIPLY"
            case SP_BLEND_MODE_ADDITIVE:
                label = "SPINE_ADDITIVE"
            default:
                continue
            }
            for pma in [false, true] {
                if  blendMode == SP_BLEND_MODE_ADDITIVE || blendMode == SP_BLEND_MODE_NORMAL, pma {
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
                let hashCode = descriptor.colorAttachments[0].computeLocalHashCode(pma: descriptor.fragmentFunction === pmaFragment)
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
        let blendModes = [
            SP_BLEND_MODE_NORMAL,
            SP_BLEND_MODE_ADDITIVE,
            SP_BLEND_MODE_MULTIPLY,
            SP_BLEND_MODE_SCREEN
        ]
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
        let blendModes = [
            SP_BLEND_MODE_NORMAL,
            SP_BLEND_MODE_ADDITIVE,
            SP_BLEND_MODE_MULTIPLY,
            SP_BLEND_MODE_SCREEN
        ]
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
    
    @inlinable
    @objc public func renderPipelineState(
        for blendMode: spBlendMode,
        premultiplyAlpha: Bool = true
    ) -> MTLRenderPipelineState? {
        let index = Int(blendMode.rawValue) << (premultiplyAlpha ? 1 : 0)
        guard index < storage.count else {
            return nil
        }
        return storage[index]
    }
            
    
}




#endif
