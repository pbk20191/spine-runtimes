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

@objcMembers
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
    
    @available(swift, obsoleted: 1.0)
    public var contentMode: ContentMode {
        get { self.sizingInfo.contentMode }
        set { self.sizingInfo.contentMode = newValue }
    }
    
    @available(swift, obsoleted: 1.0)
    public var contentAlignment: Alignment {
        get { self.sizingInfo.alignment }
        set { self.sizingInfo.alignment = newValue }
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

    @nonobjc
    public init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pipelineStatesByBlendMode: [ColorBlendPipeLineKey: MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider = SetupPoseBounds(),
        contentMode: ContentMode = .fit,
        alignment: Alignment = .center
    ) throws {
        self.model = drawable
        self.device = device
        self.pipelineStatesByBlendMode = pipelineStatesByBlendMode
        self.pSizingInput.contentMode = contentMode
        self.pSizingInput.alignment = alignment
        super.init()
        self.boundsProvider = boundsProvider
    }
    
    @available(swift, obsoleted: 1.0)
    public convenience init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pipelineStatesByBlendMode: [SpineColorBlendBridgedKey: MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment
    ) throws {
        let stateDict = pipelineStatesByBlendMode.reduce(into: [ColorBlendPipeLineKey: MTLRenderPipelineState]()) { partialResult, pair in
            partialResult[.init(pma: pair.key.pma, blendMode: pair.key.blendMode)] = pair.value
        }
        try self.init(
            drawable: drawable,
            device: device,
            pipelineStatesByBlendMode: stateDict,
            boundsProvider: boundsProvider,
            contentMode: contentMode,
            alignment: alignment
        )
    }
    
    public convenience init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pixelFormat: MTLPixelFormat,
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment
    ) throws {
        let stateDict = try Self.createDefaultPipeLineState(device: device, pixelFormat: pixelFormat)
        try self.init(
            drawable: drawable,
            device: device,
            pipelineStatesByBlendMode: stateDict,
            boundsProvider: boundsProvider,
            contentMode: contentMode,
            alignment: alignment
        )
    }
    
    
    public func callNeedsUpdate( time: CFAbsoluteTime) {
        if lastDraw == 0 {
            lastDraw = time
        }
        let delta = time - lastDraw
        delegate?.spineRenderer(self, willUpdate: time)
        self.model.update(delta: Float(delta))
        lastDraw = time
        delegate?.spineRenderer(self, didUpdate: time)
    }
    

    
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
    
    public func render(using commandBuffer: any MTLCommandBuffer, renderEncoder: any MTLRenderCommandEncoder) -> Bool {
        guard let delegate else {
            return false
        }
        let displayTransform = self.pLastSizingOutput
        var commandEntry = CommandEntry()
        withUnsafeMutablePointer(to: &commandEntry) {
            spSkeleton_render(model.pSkeleton,  model.pClipping, fill_render_command_to_entry, $0)
        }
        
        guard commandEntry.verteArray.count > 0 else {
            return true
        }
        let bufferCount = commandEntry.verteArray.withUnsafeBytes{ $0.count }
        guard let vertexBufferRef = delegate.spineRender(self, minimumSize: bufferCount) else {
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
            vertexBuffer.didModifyRange(offsetInBytes..<(offsetInBytes + bufferCount))
        }
#endif
        let atlaPageArray = sequence(first: self.model.resource.pSkeletonData.pAtlas.native.pointee.pages, next: \.pointee.next).map(\.self)
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
        
        withUnsafeBytes(of: premultiplyAlpha) {
            renderEncoder.setFragmentBytes($0.baseAddress!, length: $0.count, index: 0)
        }

        for fragment in commandEntry.metaInfo {
            
            guard let pipelineState = pipeLineStates[.init(pma: fragment.textureId.pma, blendMode: fragment.blendMode)] else {
                continue
            }
            if let currentPipeLine, currentPipeLine.isEqual(pipelineState) {
            
            } else {
                currentPipeLine = pipelineState
                renderEncoder.setRenderPipelineState(pipelineState)
            }
            if !fragment.textureId.pma, fragment.blendMode == SP_BLEND_MODE_SCREEN || fragment.blendMode == SP_BLEND_MODE_MULTIPLY {
                if !premultiplyAlpha {
                    premultiplyAlpha = true
                    withUnsafeBytes(of: premultiplyAlpha) {
                        renderEncoder.setFragmentBytes($0.baseAddress!, length: $0.count, index: 0)
                    }
                }
            } else {
                if premultiplyAlpha {
                    premultiplyAlpha = false
                    withUnsafeBytes(of: premultiplyAlpha) {
                        renderEncoder.setFragmentBytes($0.baseAddress!, length: $0.count, index: 0)
                    }
                }
            }
            let vertices = commandEntry.verteArray[fragment.slice]
            let page = atlaPageArray[fragment.textureId.index]
            if let texture = self.delegate?.fetchTexture(self, fragment.textureId.index, page) {
                if !texture.isEqual(currentTexture) {
                    currentTexture = texture
                    renderEncoder.setFragmentTexture(texture, index: Int(SpineTextureIndexBaseColor.rawValue))
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
        descriptor.vertexFunction = defaultLibrary.makeFunction(name: "spine_vertexShader")
        descriptor.fragmentFunction = defaultLibrary.makeFunction(name: "spine_fragmentShader")
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
                } else {
                    descriptor.label = label
                }
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
    
    func sourceAlphaBlendFactor(premultipliedAlpha: Bool) -> MTLBlendFactor {
        switch self {
        case SP_BLEND_MODE_NORMAL:
            return .one
        case SP_BLEND_MODE_ADDITIVE:
            return .one
        case SP_BLEND_MODE_MULTIPLY:
            return .one
        case SP_BLEND_MODE_SCREEN:
            return .oneMinusDestinationAlpha
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
            return .one
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
            return .one
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



fileprivate func fill_render_command_to_entry(
    _ head: UnsafePointer<SpineRenderBatchCommand>?,
    _ size:Int,
    _ context:UnsafeMutableRawPointer?
) {
    let contextBuffer = UnsafeMutablePointer<CommandEntry>.init(.init(context!))
    let buffer = UnsafeBufferPointer(start: head, count: size)
    contextBuffer.pointee.fillCommand(buffer)
}
