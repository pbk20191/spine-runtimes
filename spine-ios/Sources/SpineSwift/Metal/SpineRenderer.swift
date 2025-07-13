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
    
    @objc
    public let pipelineStatesByBlendMode: SpineMetalPipeLineStorage
    
    public weak var delegate: SpineRendererDelegate?
    
    @nonobjc
    internal var lastDraw: CFTimeInterval = 0
    
    @nonobjc
    private var pSpineBoundComputer: any SkeletonBoundsProvider = SetupPoseBounds()
    
    struct Disposer: BoxDisposerProtocol {
        static func dispose(_ pointer: spine_skeleton_renderer) {
            spine_skeleton_renderer_dispose(pointer)
        }
    }
    
    @nonobjc
    internal let cppRenderer = PointeeBox<spine_skeleton_renderer_wrapper, Disposer>(spine_skeleton_renderer_create())
    
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
        pipelineStatesByBlendMode: SpineMetalPipeLineStorage,
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

    @objc(initWithDrawable:device:pipelineStatesByBlendMode:boundsProvider:contentMode:alignment:)
    @available(swift, obsoleted: 1.0)
    public convenience init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        notForSwiftBlendMode: SpineMetalPipeLineStorage,
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment
    ) {

        self.init(
            drawable: drawable,
            device: device,
            pipelineStatesByBlendMode: notForSwiftBlendMode,
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
        let stateDict = try SpineMetalPipeLineStorage(device: device, pixelFormat: pixelFormat)
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
        
        let commandHead = spine_skeleton_renderer_render(&self.cppRenderer[], &self.model.skeleton)
       
        let commands = sequence(state: commandHead, next: {
            let command = $0
            if $0 != nil {
                $0 = spine_render_command_get_next($0)
            }
            return command
        })
        let pageArrayRef = spine_atlas2_get_pages(&self.model.resource.skeletonData.pAtlas[])
        let pageBuffer = UnsafeBufferPointer.init(
            start:  UnsafePointer<spine_atlas_page>(
                OpaquePointer(spine_array_atlas_page_buffer(pageArrayRef))
            ),
            count: spine_array_atlas_page_size(pageArrayRef)
        )
            
        let commandEntry = CommandEntry(commands, pageBuffer)

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
        var currentSampler = (any MTLSamplerState)?.none

        var textureMap = ContiguousArray<MTLTexture?>(repeating: nil, count: pageBuffer.count)
        var samplerMap = ContiguousArray<MTLSamplerState?>(repeating: nil, count: pageBuffer.count)
        for fragment in commandEntry.metaInfo {
            
            let page = pageBuffer[fragment.pageIndex]
            let pma = spine_atlas_page_get_pma(page)
            
            guard let pipelineState = pipeLineStates.renderPipelineState(for: fragment.blendMode, premultiplyAlpha: pma) else {
                continue
            }
            if let currentPipeLine, currentPipeLine.isEqual(pipelineState) {
            
            } else {
                currentPipeLine = pipelineState
                renderEncoder.setRenderPipelineState(pipelineState)
            }
            let vertices = commandEntry.verteArray[fragment.slice]
            if let texture = textureMap[fragment.pageIndex, safe2: self.delegate?.spineRenderer(self, textureForPage: page)] {
                if !texture.isEqual(currentTexture) {
                    currentTexture = texture
                    renderEncoder.setFragmentTexture(texture, index: Int(SpineTextureIndexBaseColor.rawValue))
                }
            } else {
                continue
            }
            if let sampler = samplerMap[fragment.pageIndex, safe2: self.delegate?.spineRenderer(self, samplerForPage: page)] {
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

}



#endif



