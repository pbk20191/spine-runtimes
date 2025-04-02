//
//  SpineMTKViewDefaultDelegate.swift
//  spine-ios
//
//  Created by 박병관 on 3/18/25.
//
#if canImport(MetalKit)
import Dispatch
import Foundation
import MetalKit
import simd
import spine_c

@objcMembers
open class SpineMTKViewDefaultDelegate: SpineRenderer, MTKViewDelegate, SpineRendererDelegate, SpineAnimationListener {
    
    private static let defaultBufferSize = 32 * 1024 // 32KB
    
    private var buffers = [MTLBuffer]()
    private let bufferingSemaphore:DispatchSemaphore
    private var currentBufferIndex: Int = 0
    public let textureLoader:MTKTextureLoader
    
    public let maxBuffer:SpineMTKBufferingStrategy

    class BufferRef: NSObject, SpineVertexBuffer {
        
        let buffer: any MTLBuffer
        let semaphore: DispatchSemaphore
        
        init(buffer: any MTLBuffer, semaphore: DispatchSemaphore) {
            self.buffer = buffer
            self.semaphore = semaphore
        }
        
        deinit {
            buffer.setPurgeableState(.empty)
            semaphore.signal()
        }
        
        let offsetInBytes: Int = 0
        
    }
    
    private func increaseBuffersSize(to size: Int) {
        buffers = (0 ..< maxBuffer.rawValue).map { _ in
            device.makeBuffer(length: size, options: [.storageModeShared, .cpuCacheModeWriteCombined])!
        }
    }
    
    public func spineRender(_ renderer: SpineSwift.SpineRenderer, minimumSize: Int) -> (any SpineVertexBuffer)? {
        if bufferingSemaphore.wait(timeout: .now()) == .timedOut {
            return nil
        }
        if buffers.isEmpty || buffers[currentBufferIndex].length < minimumSize {
            increaseBuffersSize(to: minimumSize)
        }
        let buffer = buffers[currentBufferIndex]
        currentBufferIndex = (currentBufferIndex + 1) % maxBuffer.rawValue
        buffer.setPurgeableState(.nonVolatile)
        return BufferRef(buffer: buffer, semaphore: bufferingSemaphore)
    }
    
    open func eventDispatched(drawable: SpineSwift.SpineSwiftDrawable, type: spEventType, entry: UnsafeMutablePointer<spTrackEntry>, event: UnsafePointer<spEvent>?) {
        
    }
    
    open func spineRenderer(_ renderer: SpineSwift.SpineRenderer, willUpdate: CFAbsoluteTime) {
        
    }
    
    open func spineRenderer(_ renderer: SpineSwift.SpineRenderer, didUpdate: CFAbsoluteTime) {
        
    }
    
    open func fetchTexture(_ renderer: SpineSwift.SpineRenderer, _ index: Int, _ page: UnsafePointer<spAtlasPage>) -> (any MTLTexture)? {
        assertionFailure("fetchTexture must be implemented")
        return nil
//        if let texture = page.rendererObject["kSPTexture"] as? MTLTexture {
//            return texture
//        }
//   
//        let imageName = String(cString: page.pointee.name)
//        do {
//            let url = (bundle ?? .main).url(forResource: imageName, withExtension: nil)!
//            let texture = try textureLoader.newTexture(URL: url, options: [
//                .textureUsage  : MTLTextureUsage.shaderRead.rawValue as NSNumber,
//                .textureStorageMode: MTLStorageMode.private.rawValue as NSNumber,
//                .textureCPUCacheMode: MTLCPUCacheMode.writeCombined.rawValue as NSNumber,
//                .SRGB: false as NSNumber
//            ])
//            page.rendererObject["kSPTexture"] = texture
//            return texture
//        } catch {
//            print(error)
//            return nil
//        }
//        return texture
    }
    
    
    public convenience init(
        drawable: SpineSwiftDrawable,
        commandQueue: any MTLCommandQueue,
        pixelFormat: MTLPixelFormat = .bgra8Unorm,
        boundsProvider: any SkeletonBoundsProvider = SetupPoseBounds(),
        contentMode: ContentMode = .fit,
        alignment: Alignment = .center,
        maxBuffer: SpineMTKBufferingStrategy = .double
    ) throws {
        let stateDict = try Self.createDefaultPipeLineState(device: commandQueue.device, pixelFormat: pixelFormat)
        try self.init(drawable: drawable, commandQueue: commandQueue, pipelineStatesByBlendMode: stateDict, boundsProvider: boundsProvider, contentMode: contentMode, alignment: alignment, maxBuffer: maxBuffer)
    }
    
    @nonobjc
    public init(
        drawable: SpineSwiftDrawable,
        commandQueue: any MTLCommandQueue,
        pipelineStatesByBlendMode: [ColorBlendPipeLineKey : any MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider = SetupPoseBounds(),
        contentMode: ContentMode = .fit,
        alignment: Alignment = .center,
        maxBuffer: SpineMTKBufferingStrategy = .double
    ) throws {
        self.commandQueue = commandQueue
        self.maxBuffer = maxBuffer
        self.bufferingSemaphore = .init(value: maxBuffer.rawValue)
        self.textureLoader = MTKTextureLoader(device: commandQueue.device)
        try super.init(
            drawable: drawable,
            device: commandQueue.device,
            pipelineStatesByBlendMode: pipelineStatesByBlendMode,
            boundsProvider: boundsProvider,
            contentMode: contentMode,
            alignment: alignment
        )
        drawable.animationListner = self
        delegate = self
    }
    
    @available(swift, obsoleted: 1.0)
    public convenience init(
        drawable: SpineSwiftDrawable,
        commandQueue: any MTLCommandQueue,
        pipelineStatesByBlendMode: [SpineColorBlendBridgedKey: MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment,
        maxBuffer: SpineMTKBufferingStrategy
    ) throws {
        let swiftState = pipelineStatesByBlendMode.reduce(into: [ColorBlendPipeLineKey : any MTLRenderPipelineState]()) { partialResult, pair in
            partialResult[.init(pma: pair.key.pma, blendMode: pair.key.blendMode)] = pair.value
        }
        try self.init(drawable: drawable, commandQueue: commandQueue, pipelineStatesByBlendMode: swiftState, boundsProvider: boundsProvider, contentMode: contentMode, alignment: alignment, maxBuffer: maxBuffer)
    }
    
    
    public let commandQueue:any MTLCommandQueue
    
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let contentScale:CGFloat
        #if os(macOS)
        // Start with a unit size
        let unitSize = NSSize(width: 1.0, height: 1.0)
        
        // Convert from backing to view coordinates
        let convertedSize = view.convertFromBacking(unitSize)
        
        // Calculate the scale factor
        contentScale = unitSize.width / convertedSize.width
        #else
        contentScale = view.traitCollection.displayScale
        #endif
        self.changeSize(size.applying(.init(scaleX: 1.0/contentScale, y: 1.0/contentScale)), contentScale)
    }
    
    public func draw(in view: MTKView) {
        self.callNeedsUpdate(time: CACurrentMediaTime())
        
        guard
            let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let renderPass = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass),
            let drawable = view.currentDrawable
        
        else {
            return
        }
        
        if self.render(using: commandBuffer, renderEncoder: renderEncoder) {
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        } else {
            renderEncoder.endEncoding()
        }
        
    }
    
    
}

@frozen
@objc
public enum SpineMTKBufferingStrategy: Int, Hashable, BitwiseCopyable, Sendable {
    case double = 2
    case triple = 3
}

#endif
