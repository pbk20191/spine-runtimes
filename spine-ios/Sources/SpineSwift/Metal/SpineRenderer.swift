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
    
    
    private var model:SpineSwiftDrawable
    
    
    public let device:any MTLDevice
    public let pipelineStatesByBlendMode: [ColorBlendPipeLineKey: MTLRenderPipelineState]

    public weak var delegate: SpineRendererDelegate?
    internal var lastDraw: CFTimeInterval = 0
    
    private var pSpineBoundComputer: any SkeletonBoundsProvider = SetupPoseBounds()
    
    private var pSizingInput = SizingInfoInput(
        spineNativeBound: .null,
        contentMode: .fit,
        alignment: .center,
        displaySize: .zero,
        displayScale: 1
    )

    
    private var pLastSizingOutput = SizingInfoOutput(
        size: .zero,
        viewPort: .zero,
        transform: .init(
            translation: .zero,
            scale: [1,1],
            offset: .zero
        )
    )

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

    
    public init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pipelineStatesByBlendMode: [ColorBlendPipeLineKey: MTLRenderPipelineState]
    ) throws {
        self.model = drawable
        self.device = device
        self.pipelineStatesByBlendMode = pipelineStatesByBlendMode
        super.init()
    }
    
    
    public init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pixelFormat: MTLPixelFormat
    ) throws {
        self.model = drawable
        self.device = device

        self.pipelineStatesByBlendMode = try Self.createDefaultPipeLineState(device: device, pixelFormat: pixelFormat)
        super.init()
    }
    
    
    public func callNeedsUpdate( time: CFAbsoluteTime) {
        if lastDraw == 0 {
            lastDraw = time
        }
        let delta = time - lastDraw
//         delegate?.spineRendererWillUpdate(self)
//        delegate?.spineRenderer(self, needsUpdate: delta)
        delegate?.spineRenderer(self, willUpdate: time)
        self.model.update(delta: Float(delta))
        lastDraw = time
        delegate?.spineRenderer(self, didUpdate: time)
//        delegate?.spineRendererDidUpdate(self)
    }
    

    
    public func changeSize(_ size: CGSize, _ scale: CGFloat) {
        pSizingInput.displaySize = size
        pSizingInput.displayScale = scale
        self.pLastSizingOutput = pSizingInput.generateOutput()
    }

    nonisolated
    private static func signalBuffer(buffer: any MTLCommandBuffer, ref: AnyObject) {
        buffer.addCompletedHandler { _ in
            withExtendedLifetime(ref, {})
        }
    }
    
    func render(using commandBuffer: any MTLCommandBuffer, renderEncoder: any MTLRenderCommandEncoder) -> Bool {
        guard let delegate else {
            return false
        }
        let displayTransform = self.pLastSizingOutput
        
        let commandEntry = CommandEntry(spSkeleton_render(model.pSkeleton, model.pClipping))
        guard commandEntry.verteArray.count > 0 else {
            return true
        }
        let bufferCount = commandEntry.verteArray.withUnsafeBytes{ $0.count }
        guard let vertexBufferRef = delegate.spineRender(self, minimumSize: bufferCount) else {
            return false
        }
        let vertexBuffer = vertexBufferRef.buffer
        guard vertexBuffer.length >= bufferCount else {
            return false
        }
        commandEntry.verteArray.withUnsafeBytes {
            memcpy(vertexBuffer.contents(), $0.baseAddress!, $0.count)
        }
        Self.signalBuffer(buffer: commandBuffer, ref: vertexBufferRef)
        
#if os(macOS) || targetEnvironment(macCatalyst)
        vertexBuffer.didModifyRange(0..<bufferCount)
#endif
        let atlaPageArray = sequence(first: self.model.resource.atlas.pointee.pages, next: \.pointee.next).compactMap(\.self)
        renderEncoder.setViewport(
            MTLViewport(originX: 0, originY: 0, width: Double(displayTransform.viewPort.x), height: Double(displayTransform.viewPort.y), znear: 0, zfar: 1)
        )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(SpineVertexInputIndexVertices.rawValue))
        withUnsafeBytes(of: displayTransform.transform) {
            renderEncoder.setVertexBytes($0.baseAddress!, length: $0.count, index: Int(SpineVertexInputIndexTransform.rawValue))
        }
        withUnsafeBytes(of: displayTransform.viewPort) {
            renderEncoder.setVertexBytes($0.baseAddress!, length: $0.count, index: Int(SpineVertexInputIndexViewportSize.rawValue))
        }
        var vertexStart = 0
        let pipeLineStates = self.pipelineStatesByBlendMode
        var currentPipeLine = (any MTLRenderPipelineState)?.none
        var currentTexture = (any MTLTexture)?.none
        for fragment in commandEntry.metaInfo {
            
            guard let pipelineState = pipeLineStates[.init(pma: fragment.textureId.pma, blendMode: fragment.blendMode)] else {
                continue
            }
            if let currentPipeLine, currentPipeLine.isEqual(pipelineState) {
            
            } else {
                currentPipeLine = pipelineState
                renderEncoder.setRenderPipelineState(pipelineState)
            }
            
            let vertices = commandEntry.verteArray[fragment.slice]
            let page = atlaPageArray[fragment.textureId.index]
            if let texture = self.delegate?.fetchTexture(self, fragment.textureId, page), !texture.isEqual(currentTexture) {
                currentTexture = texture
                renderEncoder.setFragmentTexture(texture, index: Int(SpineTextureIndexBaseColor.rawValue))
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
        var pipelineStates = [ColorBlendPipeLineKey: MTLRenderPipelineState]()
        var pipeLinecache = [Int:MTLRenderPipelineState]()
        for blendMode in blendModes {
            for pma in [true, false] {
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = defaultLibrary.makeFunction(name: "spine_vertexShader")
                descriptor.fragmentFunction = defaultLibrary.makeFunction(name: "spine_fragmentShader")
                descriptor.colorAttachments[0].pixelFormat = pixelFormat
                descriptor.colorAttachments[0].apply(
                    blendMode: blendMode,
                    with: pma
                )
                if let existing = pipeLinecache[descriptor.colorAttachments[0].computeLocalHashCode()] {
                    pipelineStates[.init(pma: pma, blendMode: blendMode)] = existing
                } else {
                    let newPipeLine = try device.makeRenderPipelineState(descriptor: descriptor)
                    pipeLinecache[descriptor.colorAttachments[0].computeLocalHashCode()] = newPipeLine
                    pipelineStates[.init(pma: pma, blendMode: blendMode)] = newPipeLine
                }
            }

        }
        return pipelineStates
    }


}

fileprivate extension spBlendMode {
    func sourceRGBBlendFactor(premultipliedAlpha: Bool) -> MTLBlendFactor {
        switch self {
        case SP_BLEND_MODE_NORMAL:
            return premultipliedAlpha ? .one : .sourceAlpha
        case SP_BLEND_MODE_ADDITIVE:
            return .sourceAlpha
        case SP_BLEND_MODE_MULTIPLY:
            return .destinationColor
        case SP_BLEND_MODE_SCREEN:
            return .one
        default:
            return .one // Should never be called
        }
    }
    
    func sourceAlphaBlendFactor(premultipliedAlpha: Bool) -> MTLBlendFactor {
        switch self {
        case SP_BLEND_MODE_NORMAL:
            return premultipliedAlpha ? .one : .sourceAlpha
        case SP_BLEND_MODE_ADDITIVE:
            return .sourceAlpha
        case SP_BLEND_MODE_MULTIPLY:
            return .oneMinusSourceAlpha
        case SP_BLEND_MODE_SCREEN:
            return .oneMinusSourceColor
        default:
            return .one // Should never be called
        }
    }

    var destinationRGBBlendFactor: MTLBlendFactor {
        switch self {
        case SP_BLEND_MODE_NORMAL:
            return .oneMinusSourceAlpha
        case SP_BLEND_MODE_ADDITIVE:
            return .one
        case SP_BLEND_MODE_MULTIPLY:
            return .oneMinusSourceAlpha
        case SP_BLEND_MODE_SCREEN:
            return .oneMinusSourceColor
        default:
            return .one // Should never be called
        }
    }

    var destinationAlphaBlendFactor: MTLBlendFactor {
        switch self {
        case SP_BLEND_MODE_NORMAL:
            return .oneMinusSourceAlpha
        case SP_BLEND_MODE_ADDITIVE:
            return .one
        case SP_BLEND_MODE_MULTIPLY:
            return .oneMinusSourceAlpha
        case SP_BLEND_MODE_SCREEN:
            return .oneMinusSourceColor
        default:
            return .one // Should never be called
        }
    }
}

fileprivate extension MTLRenderPipelineColorAttachmentDescriptor {
    
    func apply(blendMode: spBlendMode, with premultipliedAlpha: Bool) {
        isBlendingEnabled = true
        sourceRGBBlendFactor = blendMode.sourceRGBBlendFactor(premultipliedAlpha: premultipliedAlpha)
        sourceAlphaBlendFactor = blendMode.sourceAlphaBlendFactor(premultipliedAlpha: premultipliedAlpha)
        destinationRGBBlendFactor = blendMode.destinationRGBBlendFactor
        destinationAlphaBlendFactor = blendMode.destinationAlphaBlendFactor
    }
    
}

fileprivate extension MTLRenderPipelineColorAttachmentDescriptor {
    
    func computeLocalHashCode() -> Int {
        var hasher = Hasher()
        hasher.combine(self.sourceRGBBlendFactor)
        hasher.combine(self.sourceAlphaBlendFactor)
        hasher.combine(self.destinationRGBBlendFactor)
        hasher.combine(self.destinationAlphaBlendFactor)
        return hasher.finalize()
    }
    
}

#endif
