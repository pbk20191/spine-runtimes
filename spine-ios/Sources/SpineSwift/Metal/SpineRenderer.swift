//
//  SpineRenderer.swift
//  spine-ios
//
//  Created by 박병관 on 3/16/25.
//

import spine_c
import simd
import SpineShadersStructs
#if canImport(Metal)
import Metal

open class SpineRenderer: NSObject {
    
    @nonobjc
    private var model:SpineSwiftDrawable
    
    public let device:any MTLDevice
    
    @nonobjc
    public let pipelineStatesByBlendMode: [ColorBlendPipeLineKey: MTLRenderPipelineState]
    
    public weak var delegate: SpineRendererDelegate?
    
    @nonobjc
    internal var lastDraw: CFTimeInterval = 0
    
    @nonobjc
    private var pSpineBoundComputer: any SkeletonBoundsProvider = SetupPoseBounds()
    
    @nonobjc
    internal let pClipping = spSkeletonClipping_create()!
    
    @nonobjc
    private var pSizingInput = SizingInfoInput(
        spineNativeBound: .null,
        contentMode: .fit,
        alignment: .center,
        displaySize: .zero,
        displayScale: 1
    )

    @nonobjc
    private var pLastSizingOutput = SizingInfoOutput(
        size: .zero,
        viewPort: .zero,
        transform: .init(
            translation: .zero,
            scale: [1,1],
            offset: .zero
        )
    )
    
    public var currentSizingOutput: SizingInfoOutput {
        pLastSizingOutput
    }

    @objc
    public var boundsProvider: any SkeletonBoundsProvider {
        get { pSpineBoundComputer }
        set {
            pSpineBoundComputer = newValue
            pSizingInput.spineNativeBound =  newValue.computeBounds(for: model)
            pLastSizingOutput = pSizingInput.generateOutput()
        }
    }
    
    public var sizingInfo: SizingInfoInput {
        get { self.pSizingInput }
        set {
            self.pSizingInput = newValue
            self.pLastSizingOutput = newValue.generateOutput()
        }
    }
    
    @objc
    @available(swift, obsoleted: 1.0)
    public var contentMode: ContentMode {
        get { self.sizingInfo.contentMode }
        set { self.sizingInfo.contentMode = newValue }
    }
    
    @objc
    @available(swift, obsoleted: 1.0)
    public var contentAlignment: Alignment {
        get { self.sizingInfo.alignment }
        set { self.sizingInfo.alignment = newValue }
    }
    
    @objc
    public var drawable:SpineSwiftDrawable {
        get { model }
        set {
            if newValue === model {
                return
            }
            let nativeBound = self.pSpineBoundComputer.computeBounds(for: newValue)
            self.model = newValue
            self.lastDraw = 0
            self.pSizingInput.spineNativeBound = nativeBound
            self.pLastSizingOutput = self.pSizingInput.generateOutput()
        }
    }

    @nonobjc
    public init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pipelineStatesByBlendMode: [ColorBlendPipeLineKey: MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider = SetupPoseBounds(),
        contentMode: ContentMode = .fit,
        alignment: Alignment = .center
    )  {
        self.model = drawable
        self.device = device
        self.pipelineStatesByBlendMode = pipelineStatesByBlendMode
        self.pSizingInput.contentMode = contentMode
        self.pSizingInput.alignment = alignment
        super.init()
        self.boundsProvider = boundsProvider
    }
    
    deinit {
        spSkeletonClipping_dispose(self.pClipping)
    }
    
    @objc
    @available(swift, obsoleted: 1.0)
    public convenience init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pipelineStatesByBlendMode: [SpineColorBlendBridgedKey: MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment
    ) {
        let stateDict = pipelineStatesByBlendMode.reduce(into: [ColorBlendPipeLineKey: MTLRenderPipelineState]()) { partialResult, pair in
            partialResult[.init(pma: pair.key.pma, blendMode: pair.key.blendMode)] = pair.value
        }
        self.init(
            drawable: drawable,
            device: device,
            pipelineStatesByBlendMode: stateDict,
            boundsProvider: boundsProvider,
            contentMode: contentMode,
            alignment: alignment
        )
    }
    
    @objc
    public convenience init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pixelFormat: MTLPixelFormat,
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment
    ) throws {
        let stateDict = try Self.createDefaultPipeLineState(device: device, pixelFormat: pixelFormat)
        self.init(
            drawable: drawable,
            device: device,
            pipelineStatesByBlendMode: stateDict,
            boundsProvider: boundsProvider,
            contentMode: contentMode,
            alignment: alignment
        )
    }
    
    @objc
    public func callNeedsUpdate( time: CFAbsoluteTime) {
        if lastDraw == 0 {
            lastDraw = time
        }
        let delta = time - lastDraw
        delegate?.spineRenderer(self, willUpdateAtTime: time)
        self.model.update(delta: Float(delta))
        lastDraw = time
        delegate?.spineRenderer(self, didUpdateAtTime: time)
    }
    
    @objc
    public func changeSize(_ size: CGSize, _ scale: CGFloat) {
        pSizingInput.displaySize = size
        pSizingInput.displayScale = scale
        self.pLastSizingOutput = pSizingInput.generateOutput()
    }

    @nonobjc
    nonisolated
    private static func signalBuffer(buffer: any MTLCommandBuffer, ref: AnyObject) {
        buffer.addCompletedHandler { _ in
            withExtendedLifetime(ref, {})
        }
    }
    
    @objc
    public func encode(
        using commandBuffer: any MTLCommandBuffer,
        renderEncoder: any MTLRenderCommandEncoder
    ) -> Bool {
        guard let delegate else {
            return false
        }
        let displayTransform = self.pLastSizingOutput
        
        let commandEntry = withUnsafePointer(to: &self.model.resource.skeletonData.atlas[]) { ref in
            RenderCallBackContext.render(ref, &model.skeleton, self.pClipping)
        }
        
        guard commandEntry.verteArray.count > 0 else {
            return true
        }
        let bufferCount = commandEntry.verteArray.withUnsafeBytes{ $0.count }
        guard let vertexBufferRef = delegate.spineRenderer(self, vertexBufferForMinimumSize: bufferCount) else {
            return false
        }
        let vertexBuffer = vertexBufferRef.buffer
        let offsetInBytes = vertexBufferRef.offsetInBytes
        guard vertexBuffer.length >= bufferCount else {
            return false
        }
        renderEncoder.pushDebugGroup("spine_render")
        defer {
            renderEncoder.popDebugGroup()
        }
        commandEntry.verteArray.withUnsafeBytes {
            let _ = memcpy(vertexBuffer.contents().advanced(by: offsetInBytes), $0.baseAddress!, $0.count)
        }
        Self.signalBuffer(buffer: commandBuffer, ref: vertexBufferRef)
        
#if os(macOS) || targetEnvironment(macCatalyst)
        if vertexBuffer.storageMode == .managed {
            if #available(macCatalyst 14.0, macOS 10.11, *) {
                vertexBuffer.didModifyRange(offsetInBytes..<(offsetInBytes + bufferCount))
            }
        }
#endif
        let atlaPageArray = sequence(first: self.model.resource.pSkeletonData.pAtlas[].pages, next: \.pointee.next).map(\.self)
        renderEncoder.setViewport(
            MTLViewport(
                originX: displayTransform.viewPort.origin.x,
                originY: displayTransform.viewPort.origin.y,
                width: displayTransform.viewPort.width,
                height: displayTransform.viewPort.height,
                znear: 0,
                zfar: 1
            )
        )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: offsetInBytes, index: Int(SpineVertexInputIndexVertices.rawValue))
        withUnsafeBytes(of: displayTransform.transform) {
            renderEncoder.setVertexBytes($0.baseAddress!, length: $0.count, index: Int(SpineVertexInputIndexTransform.rawValue))
        }
        let viewPortSize:SIMD2<UInt32> = [
            .init(displayTransform.viewPort.size.width),
            .init(displayTransform.viewPort.size.height)
        ]
        withUnsafeBytes(of: viewPortSize) {
            renderEncoder.setVertexBytes($0.baseAddress!, length: $0.count, index: Int(SpineVertexInputIndexViewportSize.rawValue))
        }
        var vertexStart = 0
        let pipeLineStates = self.pipelineStatesByBlendMode
        var currentPipeLine = (any MTLRenderPipelineState)?.none
        var currentTexture = (any MTLTexture)?.none
        var premultiplyAlpha = false
        var currentSampler = (any MTLSamplerState)?.none
        withUnsafeBytes(of: premultiplyAlpha) {
            renderEncoder.setFragmentBytes($0.baseAddress!, length: $0.count, index: 0)
        }
        var textureMap = [UnsafeMutablePointer<spAtlasPage>: MTLTexture]()
        var samplerMap = [UnsafeMutablePointer<spAtlasPage>: MTLSamplerState]()
        for fragment in commandEntry.metaInfo {
            let page = atlaPageArray[fragment.pageIndex]
            let pma = page.pointee.pma != 0
            guard let pipelineState = pipeLineStates[.init(pma: pma, blendMode: fragment.blendMode)] else {
                continue
            }
            if let currentPipeLine, currentPipeLine.isEqual(pipelineState) {
            
            } else {
                currentPipeLine = pipelineState
                renderEncoder.setRenderPipelineState(pipelineState)
            }
            let vertices = commandEntry.verteArray[fragment.slice]
            if let texture = textureMap[page, safe2: self.delegate?.spineRenderer(self, textureForPage: page)] {
                if !texture.isEqual(currentTexture) {
                    currentTexture = texture
                    renderEncoder.setFragmentTexture(texture, index: Int(SpineTextureIndexBaseColor.rawValue))
                }
            } else {
                continue
            }
            if let sampler = samplerMap[page, safe2: self.delegate?.spineRenderer(self, samplerForPage: page)] {
                if !sampler.isEqual(currentSampler) {
                    currentSampler = sampler
                    renderEncoder.setFragmentSamplerState(sampler, index: 0)
                }
            } else {
                continue
            }
            renderEncoder.drawPrimitives(
                type: .triangle,
                vertexStart: vertexStart,
                vertexCount: vertices.count
            )
            vertexStart += vertices.count
        }
        return true
    }
    
    @nonobjc
    public static func createDefaultPipeLineState(device: MTLDevice, pixelFormat:MTLPixelFormat) throws -> [ColorBlendPipeLineKey: MTLRenderPipelineState] {
        let bundle: Bundle
        #if SWIFT_PACKAGE // SPM
        bundle = .module
        #else
        bundle = Bundle(for: SpineRenderer.self)
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
            for pma in [true, false] {
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
                } else {
                    let newPipeLine = try device.makeRenderPipelineState(descriptor: descriptor)
                    pipeLinecache[hashCode] = newPipeLine
                    pipelineStates[.init(pma: pma, blendMode: blendMode)] = newPipeLine
                }
            }

        }
        return pipelineStates
    }
    
    @objc(createDefaultPipeLineState:device:pixelFormat:)
    @available(swift, obsoleted: 1.0)
    public static func __createDefaultPipeLineState(device: MTLDevice, pixelFormat:MTLPixelFormat) throws -> [SpineColorBlendBridgedKey: MTLRenderPipelineState] {
        let swiftState = try Self.createDefaultPipeLineState(device: device, pixelFormat: pixelFormat)
        return swiftState.reduce(into: [SpineColorBlendBridgedKey:MTLRenderPipelineState]()) { partialResult, pair in
            partialResult[.init(pma: pair.key.pma, blendMode: pair.key.blendMode)] = pair.value
        }
    }
    
    @objc(currentPipeLineDictionary)
    @available(swift, obsoleted: 1.0)
    public func __currentPipeLineDictionary() -> [SpineColorBlendBridgedKey: any MTLRenderPipelineState] {
        self.pipelineStatesByBlendMode.reduce(into: [SpineColorBlendBridgedKey: any MTLRenderPipelineState]()) { partialResult, pair in
            partialResult[.init(pma: pair.key.pma, blendMode: pair.key.blendMode)] = pair.value
        }
    }


}

fileprivate extension spBlendMode {
    
    func sourceRGBBlendFactor(premultipliedAlpha: Bool) -> MTLBlendFactor {
        switch self {
        case SP_BLEND_MODE_NORMAL:
            return premultipliedAlpha ? .one : .sourceAlpha
        case SP_BLEND_MODE_ADDITIVE:
            return premultipliedAlpha ? .one : .sourceAlpha
        case SP_BLEND_MODE_MULTIPLY:
            // requires src rgb chnnel to be multiplied by 1 alpha src before blending in non pma
            return  .destinationColor
        case SP_BLEND_MODE_SCREEN:
            // requires src rgb chnnel to be multiplied by 1 alpha src before blending in non pma
            return  .oneMinusDestinationColor
        default:
            return .one // Should never be called
        }
    }

}

fileprivate extension MTLRenderPipelineColorAttachmentDescriptor {
    
    func apply(blendMode: spBlendMode, with premultipliedAlpha: Bool) {
        isBlendingEnabled = true
        sourceRGBBlendFactor = blendMode.sourceRGBBlendFactor(premultipliedAlpha: premultipliedAlpha)
        sourceAlphaBlendFactor = blendMode == SP_BLEND_MODE_SCREEN ? .oneMinusDestinationAlpha : .one
        switch blendMode {
        case SP_BLEND_MODE_NORMAL, SP_BLEND_MODE_MULTIPLY:
            destinationAlphaBlendFactor = .oneMinusSourceAlpha
            destinationRGBBlendFactor = .oneMinusSourceAlpha
        case SP_BLEND_MODE_ADDITIVE, SP_BLEND_MODE_SCREEN:
            destinationAlphaBlendFactor = .one
            destinationRGBBlendFactor = .one
        default:
            destinationRGBBlendFactor = .one
            destinationAlphaBlendFactor = .one
        }
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

#endif



