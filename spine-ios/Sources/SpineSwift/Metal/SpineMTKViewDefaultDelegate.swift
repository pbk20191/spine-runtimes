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
import spine_c

open class SpineMTKViewDefaultDelegate: SpineRenderer, MTKViewDelegate, SpineRendererDelegate, SpineAnimationListener {
    
    private static let defaultBufferSize = 32 * 1024 // 32KB
    
    private var buffers = [MTLBuffer]()
    private let bufferingSemaphore = DispatchSemaphore(value: 3)
    private var currentBufferIndex: Int = 0
    public let textureLoader:MTKTextureLoader
    public var bundle:Bundle?
    
    class BufferRef: NSObject, SpineVertexBuffer {
        
        let buffer: any MTLBuffer
        let semaphore: DispatchSemaphore
        
        init(buffer: any MTLBuffer, semaphore: DispatchSemaphore) {
            self.buffer = buffer
            self.semaphore = semaphore
        }
        
        deinit {
            semaphore.signal()
        }
        
        
    }
    
    private func increaseBuffersSize(to size: Int) {
        buffers = (0 ..< 3).map { _ in
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
        currentBufferIndex = (currentBufferIndex + 1) % 3
        return BufferRef(buffer: buffer, semaphore: bufferingSemaphore)
    }
    
    open func eventDispatched(drawable: SpineSwift.SpineSwiftDrawable, type: spEventType, entry: UnsafeMutablePointer<spTrackEntry>, event: UnsafePointer<spEvent>?) {
        
    }
    
    open func spineRenderer(_ renderer: SpineSwift.SpineRenderer, willUpdate: CFAbsoluteTime) {
        
    }
    
    open func spineRenderer(_ renderer: SpineSwift.SpineRenderer, didUpdate: CFAbsoluteTime) {
        
    }
    
    open func fetchTexture(_ renderer: SpineSwift.SpineRenderer, _ item: TextureIdentifier, _ page: UnsafePointer<spAtlasPage>) -> (any MTLTexture)? {
        if let texture = page.rendererObject["kSPTexture"] as? MTLTexture {
            return texture
        }
   
        let imageName = String(cString: page.pointee.name)
        do {
            let url = (bundle ?? .main).url(forResource: imageName, withExtension: nil)!
            let texture = try! textureLoader.newTexture(URL: url, options: [
                .textureUsage  : MTLTextureUsage.shaderRead.rawValue as NSNumber,
                .textureStorageMode: MTLStorageMode.private.rawValue as NSNumber,
                .textureCPUCacheMode: MTLCPUCacheMode.writeCombined.rawValue as NSNumber,
                .SRGB: false as NSNumber
            ])
            page.rendererObject["kSPTexture"] = texture
            return texture
        } catch {
            print(error)
            return nil
        }
//        return texture
    }
    
    
    public override init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pixelFormat: MTLPixelFormat
    ) throws {
        self.commandQueue = device.makeCommandQueue()!

        self.textureLoader = MTKTextureLoader(device: device)
        try super.init(drawable: drawable, device: device, pixelFormat: pixelFormat)
        drawable.animationListner = self
        delegate = self
        self.boundsProvider = self.boundsProvider
    }
    
    public override init(
        drawable: SpineSwiftDrawable,
        device: any MTLDevice,
        pipelineStatesByBlendMode: [ColorBlendPipeLineKey : any MTLRenderPipelineState]
    ) throws {
        self.commandQueue = device.makeCommandQueue()!

        self.textureLoader = MTKTextureLoader(device: device)
        try super.init(drawable: drawable, device: device, pipelineStatesByBlendMode: pipelineStatesByBlendMode)
        drawable.animationListner = self
        delegate = self
        self.boundsProvider = self.boundsProvider

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
        let displaySize = size.applying(.init(scaleX: 1.0/contentScale, y: 1.0/contentScale))
        self.changeSize(displaySize, contentScale)
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

#endif
