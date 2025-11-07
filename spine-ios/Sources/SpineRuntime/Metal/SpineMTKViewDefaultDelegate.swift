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
    import SpineC
import spine_apple_extension

    open class SpineMTKViewDefaultDelegate: SpineRenderer, MTKViewDelegate, SpineRendererDelegate {

        @objc public var textureBundle: Bundle?

        private static let defaultBufferSize = 32 * 1024  // 32KB

        private var buffers = [MTLBuffer]()
        private let bufferingSemaphore: DispatchSemaphore
        private var currentBufferIndex: Int = 0

        public let maxBuffer: SpineMTKBufferingStrategy

        private func increaseBuffersSize(to size: Int) {
            buffers = (0..<maxBuffer.rawValue).map { _ in
                device.makeBuffer(length: size, options: [.storageModeShared, .cpuCacheModeWriteCombined])!
            }
        }

        open func spineRenderer(_ renderer: SpineRenderer, vertexBufferForMinimumSize minimumSize: Int) -> (any SpineVertexBuffer)? {
            if bufferingSemaphore.wait(timeout: .now()) == .timedOut {
                return nil
            }
            if buffers.isEmpty || buffers[currentBufferIndex].length < minimumSize {
                increaseBuffersSize(to: minimumSize)
            }
            let buffer = buffers[currentBufferIndex]
            currentBufferIndex = (currentBufferIndex + 1) % maxBuffer.rawValue
            buffer.setPurgeableState(.nonVolatile)
            return ScratchBufferHolder(buffer: buffer, semaphore: bufferingSemaphore)
        }

        private var samplerCache = [AtlasSamplerConfig: any MTLSamplerState]()

        open func spineRenderer(_ renderer: SpineRenderer, samplerForPage page: spine_atlas_page) -> any MTLSamplerState {
            let rendererObject = page.dictionaryTexture
            let config = AtlasSamplerConfig(
                min: .init(rawValue: spine_atlas_page_get_min_filter(page)),
                mag: .init(rawValue: spine_atlas_page_get_mag_filter(page)),
                uwrap: .init(rawValue: spine_atlas_page_get_u_wrap(page)),
                vwrap: .init(rawValue: spine_atlas_page_get_v_wrap(page))
            )
            if let sampler = samplerCache[config] {
                return sampler
            }
            let samplerKey = "kSpineMetalSampler"
            if let sampler = rendererObject[samplerKey] as? any MTLSamplerState {
                if samplerCache[config] == nil {
                    samplerCache[config] = sampler
                }
                return sampler
            }
            let samplerDescriptor = config.generateSamplerDescriptor()
            let sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
            rendererObject[samplerKey] = sampler
            samplerCache[config] = sampler
            return sampler
        }

        open func spineRenderer(_ renderer: SpineRenderer, didUpdateAtTime time: CFAbsoluteTime) {}

        open func spineRenderer(_ renderer: SpineRenderer, willUpdateAtTime time: CFAbsoluteTime) {}

        open func spineRenderer(_ renderer: SpineRenderer, textureForPage page: spine_atlas_page) -> (any MTLTexture)? {
            let textureKey = "kSpineMetalTexture"
            let userInfo = page.dictionaryTexture
            if let texture = userInfo[textureKey] as? MTLTexture {
                return texture
            }
            let bundle = self.textureBundle
            //        String(cString: <#T##[CChar]#>, encoding: <#T##String.Encoding#>)


            let textureName = String(cString: spine_atlas_page_get_name(page))
            let texturePath = String(cString: spine_atlas_page_get_texture_path(page))
            let option =
                [
                    .SRGB: false as NSNumber,
                    .textureStorageMode: MTLStorageMode.private.rawValue as NSNumber,
                    .textureCPUCacheMode: MTLCPUCacheMode.writeCombined.rawValue as NSNumber,
                    .origin: MTKTextureLoader.Origin.topLeft.rawValue,
                    .textureUsage: MTLTextureUsage.shaderRead.rawValue as NSNumber,
                ] as [MTKTextureLoader.Option: Any]
            if textureName != texturePath {
                let url = URL(fileURLWithPath: texturePath)
                do {
                    let texture = try MTKTextureLoader(device: device)
                        .newTexture(URL: url, options: option)
                    userInfo[textureKey] = texture
                    return texture
                } catch {
                    #if DEBUG
                        print("Error loading texture: \(error)")
                    #endif
                }
            }
            let assetName = textureName.replacingOccurrences(of: ".png", with: "")
            do {
                let texture = try MTKTextureLoader(device: device)
                    .newTexture(name: assetName, scaleFactor: 3, bundle: bundle, options: option)
                userInfo[textureKey] = texture
                return texture
            } catch {
                #if DEBUG
                    print("Error loading texture: \(error)")
                #endif
            }
            return nil
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
            let stateDict = try SpineMetalPipeLineStorage(device: commandQueue.device, pixelFormat: pixelFormat)
            self.init(
                drawable: drawable, commandQueue: commandQueue, pipelineStatesByBlendMode: stateDict, boundsProvider: boundsProvider,
                contentMode: contentMode, alignment: alignment, maxBuffer: maxBuffer)
        }

        @nonobjc
        public init(
            drawable: SpineSwiftDrawable,
            commandQueue: any MTLCommandQueue,
            pipelineStatesByBlendMode: SpineMetalPipeLineStorage,
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
            delegate = self
        }

        @objc(initWithDrawable:commandQueue:pipelineStatesByBlendMode:boundsProvider:contentMode:alignment:maxBuffer:)
        @available(swift, obsoleted: 1.0)
        public convenience init(
            drawable: SpineSwiftDrawable,
            commandQueue: any MTLCommandQueue,
            notForSwiftBlendStates: SpineMetalPipeLineStorage,
            boundsProvider: any SkeletonBoundsProvider,
            contentMode: ContentMode,
            alignment: Alignment,
            maxBuffer: SpineMTKBufferingStrategy
        ) {
            self.init(
                drawable: drawable, commandQueue: commandQueue, pipelineStatesByBlendMode: notForSwiftBlendStates, boundsProvider: boundsProvider,
                contentMode: contentMode, alignment: alignment, maxBuffer: maxBuffer)
        }

        @objc
        public let commandQueue: any MTLCommandQueue


        open func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            let contentScale: CGFloat
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
            self.changeSize(size.applying(.init(scaleX: 1.0 / contentScale, y: 1.0 / contentScale)), contentScale)
        }

        open func draw(in view: MTKView) {
            self.callNeedsUpdate(time: CACurrentMediaTime())

            guard
                let commandBuffer = self.commandQueue.makeCommandBuffer(),
                let renderPass = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable

            else {
                return
            }
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!

            if self.encode(using: commandBuffer, renderEncoder: renderEncoder) {
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
