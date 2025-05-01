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

open class SpineMTKViewDefaultDelegate: SpineRenderer, MTKViewDelegate, SpineRendererDelegate, SpineAnimationListener {

    
    
    private static let defaultBufferSize = 32 * 1024 // 32KB
    
    private var buffers = [MTLBuffer]()
    private let bufferingSemaphore:DispatchSemaphore
    private var currentBufferIndex: Int = 0
    
    public let maxBuffer:SpineMTKBufferingStrategy
    
    final class ScratchBufferSwiftProxy {
        
        @nonobjc
        let buffer:(any MTLBuffer)
        @nonobjc
        let semaphore:DispatchSemaphore
        
        typealias MethodLookup = @convention(c) (AnyObject, Selector, Selector) -> (Unmanaged<NSObject>?)
        
        
        @nonobjc
        let methodTable:MethodLookup?
        
        @nonobjc static var methodSelector: Selector {
           Selector( "methodSignatureForSelector:")
        }
        
        @nonobjc
        init(buffer: any MTLBuffer, semaphore: DispatchSemaphore) {
            self.buffer = buffer
            self.semaphore = semaphore
            let type = type(of: buffer)
            if let method = class_getInstanceMethod(type, Self.methodSelector) {
                let imp = method_getImplementation(method)
                self.methodTable = unsafeBitCast(imp, to: MethodLookup.self)
            } else {
                self.methodTable = nil
            }
        }
        
        deinit {
            buffer.setPurgeableState(.empty)
            semaphore.signal()
        }
        
        @objc(forwardingTargetForSelector:)
        func forwardingTarget(for aSelector: Selector!) -> Any? {
            guard buffer.responds(to: aSelector) else { return nil }
            #if !DEBUG
            return buffer
            #endif
            
            var description = protocol_getMethodDescription(MTLBuffer.self, aSelector, true, true)
            if description.name == aSelector {
                return nil
            }
            description = protocol_getMethodDescription(MTLBuffer.self, aSelector, false, true)
            if description.name == aSelector {
                return nil
            }
            return buffer
        }
        
//        @objc(resolveClassMethod:)
//        class func resolveClassMethod(_ sel:Selector) -> Bool {
//            false
//        }
//
//        @objc(resolveInstanceMethod:)
//        class func resolveInstanceMethod(_ sel:Selector) -> Bool {
//            return false
//        }
//
//        @objc(instancesRespondToSelector:)
//        class func instancesRespond(_ sel:Selector) -> Bool {
//            false
//        }
        
        @objc(conformsToProtocol:)
        func conforms(to aProtocol: Protocol) -> Bool {
            return buffer.conforms(to: aProtocol)
        }
        
        @objc(respondsToSelector:)
        func responds(to aSelector: Selector) -> Bool {
            return buffer.responds(to: aSelector)
        }
        
        
        @available(swift, obsoleted: 1.0)
        @objc(forwardInvocation:)
        func forwardInvocation(_ invocation: NSInvocation) {
            invocation.invoke(withTarget: buffer)
        }
        
        @available(swift, obsoleted: 1.0)
        @objc(methodSignatureForSelector:)
        func methodSignature(for selector: Selector) -> NSMethodSignature! {
            guard let methodTable else { return nil }
            let object = methodTable(self.buffer, Self.methodSelector, selector)?.takeUnretainedValue()
            let signature = object as? NSMethodSignature
            return signature
        }
        
        @objc(isProxy)
        func isProxy() -> Bool {
            return true
        }
        
        @objc(isEqual:)
        func isEqual(_ object: Any?) -> Bool {
            return buffer.isEqual(object)
        }
        
        @objc(hash)
        var hash:Int {
            buffer.hash
        }
        
        @objc(isKindOfClass:)
        func isKind(of aClass: AnyClass) -> Bool {
            return buffer.isKind(of: aClass)
        }
        
        @objc(isMemberOfClass:)
        func isMember(of aClass: AnyClass) -> Bool {
            return buffer.isMember(of: aClass)
        }
        
        @objc(self)
        func `self`() -> (any MTLBuffer) {
            buffer.`self`()
        }
        
        @objc
        func contents() -> UnsafeMutableRawPointer {
            buffer.contents()
        }
        
        @objc
        var length: Int {
            buffer.length
        }
        
        @objc
        var storageMode: MTLStorageMode {
            buffer.storageMode
        }
    }
    
    private func increaseBuffersSize(to size: Int) {
        buffers = (0 ..< maxBuffer.rawValue).map { _ in
            device.makeBuffer(length: size, options: [.storageModeShared, .cpuCacheModeWriteCombined])!
        }
    }
    
    public func spineRenderer(_ renderer: SpineRenderer, vertexBufferForMinimumSize minimumSize: Int, offsetInBytes: UnsafeMutablePointer<Int>) -> (any MTLBuffer)? {
        if bufferingSemaphore.wait(timeout: .now()) == .timedOut {
            return nil
        }
        if buffers.isEmpty || buffers[currentBufferIndex].length < minimumSize {
            increaseBuffersSize(to: minimumSize)
        }
        let buffer = buffers[currentBufferIndex]
        currentBufferIndex = (currentBufferIndex + 1) % maxBuffer.rawValue
        buffer.setPurgeableState(.nonVolatile)
        offsetInBytes.pointee = 0
        let proxy = ScratchBufferSwiftProxy(buffer: buffer, semaphore: bufferingSemaphore)
        let ref = proxy as! (any MTLBuffer)
        return ref
    }
    
    private var samplerCache = [AtlasSamplerConfig: any MTLSamplerState]()
    
    public func spineRenderer(_ renderer: SpineRenderer, samplerForPage page: UnsafePointer<spAtlasPage>) -> any MTLSamplerState {
        let config = AtlasSamplerConfig(
            min: .init(rawValue: page.pointee.minFilter),
            mag: .init(rawValue: page.pointee.magFilter),
            uwrap: .init(rawValue: page.pointee.uWrap),
            vwrap: .init(rawValue: page.pointee.vWrap)
        )
        if let sampler = samplerCache[config] {
            return sampler
        }
        let samplerKey = "kSpineMetalSampler"
        if let sampler = page.rendererObject[samplerKey] as? any MTLSamplerState {
            if samplerCache[config] == nil {
                samplerCache[config] = sampler
            }
            return sampler
        }
        let samplerDescriptor = config.generateSamplerDescriptor()
        let sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
        page.rendererObject[samplerKey] = sampler
        samplerCache[config] = sampler
        return sampler
    }
    
    open func eventDispatched(drawable: SpineSwift.SpineSwiftDrawable, type: spEventType, entry: UnsafeMutablePointer<spTrackEntry>, event: UnsafePointer<spEvent>?) {}
    
    open func spineRenderer(_ renderer: SpineRenderer, didUpdateAtTime time: CFAbsoluteTime) {}
    
    open func spineRenderer(_ renderer: SpineRenderer, willUpdateAtTime time: CFAbsoluteTime) {}
    
    open func spineRenderer(_ renderer: SpineRenderer, textureForPage page: UnsafePointer<spAtlasPage>) -> (any MTLTexture)? {
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
    
    @objc
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
        self.init(drawable: drawable, commandQueue: commandQueue, pipelineStatesByBlendMode: stateDict, boundsProvider: boundsProvider, contentMode: contentMode, alignment: alignment, maxBuffer: maxBuffer)
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
    ) {
        self.commandQueue = commandQueue
        self.maxBuffer = maxBuffer
        self.bufferingSemaphore = .init(value: maxBuffer.rawValue)
        super.init(
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
    
    @objc
    @available(swift, obsoleted: 1.0)
    public convenience init(
        drawable: SpineSwiftDrawable,
        commandQueue: any MTLCommandQueue,
        pipelineStatesByBlendMode: [SpineColorBlendBridgedKey: MTLRenderPipelineState],
        boundsProvider: any SkeletonBoundsProvider,
        contentMode: ContentMode,
        alignment: Alignment,
        maxBuffer: SpineMTKBufferingStrategy
    ) {
        let swiftState = pipelineStatesByBlendMode.reduce(into: [ColorBlendPipeLineKey : any MTLRenderPipelineState]()) { partialResult, pair in
            partialResult[.init(pma: pair.key.pma, blendMode: pair.key.blendMode)] = pair.value
        }
        self.init(drawable: drawable, commandQueue: commandQueue, pipelineStatesByBlendMode: swiftState, boundsProvider: boundsProvider, contentMode: contentMode, alignment: alignment, maxBuffer: maxBuffer)
    }
    
    @objc
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
            let drawable = view.currentDrawable
        
        else {
            return
        }
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!

        if self.encode(renderEncoder: renderEncoder) {
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
