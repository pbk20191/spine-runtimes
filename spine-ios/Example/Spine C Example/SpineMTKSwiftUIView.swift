//
//  SpineMTKSwiftUIView.swift
//  Spine C Example
//
//  Created by 박병관 on 4/2/25.
//

import Foundation
import MetalKit
import SpineSwift
import SwiftUI
import spine_c

class SpineViewDelegate: SpineMTKViewDefaultDelegate {
    
    override func fetchTexture(_ renderer: SpineRenderer, _ index: Int, _ page: UnsafePointer<spAtlasPage>) -> (any MTLTexture)? {
        let textureKey = "KSpineMetalTexture"
        if let texture = page.rendererObject[textureKey] as? MTLTexture {
            return texture
        }
        
        let option = [
            .SRGB: false as NSNumber,
            .textureStorageMode: MTLStorageMode.private.rawValue as NSNumber,
            .textureCPUCacheMode: MTLCPUCacheMode.writeCombined.rawValue as NSNumber,
            .origin: MTKTextureLoader.Origin.topLeft.rawValue
        ] as [MTKTextureLoader.Option : Any]
        let name = String(cString: page.pointee.name).replacingOccurrences(of: ".png", with: "")
        do {
            if let url = Bundle.main.url(forResource: name, withExtension: "png") {
                let textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
                let texture = try textureLoader.newTexture(
                    URL: url,
                    options: option
                )
                page.rendererObject[textureKey] = texture
                return texture
            }
            return nil
        } catch {
            dump(error)
            return nil
        }

    }
    
}

class TaggedDrawable: SpineSwiftDrawable {
    
    private(set) var tag:String?
    
    func setTag(_ tag:String) {
        self.tag = tag
    }
    
}

struct SpineMTKSwiftUIView: Equatable {
    
    let atlasURL: URL
    let jsonURL: URL
    let animationName: String?
    let tag:String
    
    func makeCoordinator() -> SpineViewDelegate {
        let atlas = try! SpineAtlasBox(path: atlasURL.path)
        let shared = try! SpineSkeletonDataBox(atlas: atlas, jsonPath: jsonURL.path)
        let drawable = TaggedDrawable(resource: .init(skeletonData: shared))
        drawable.setTag(tag)
        if let animationName = self.animationName {
            spAnimationState_setAnimationByName(&drawable.animationState, 0, animationName, 1)
        }
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()!
        let delegate = try! SpineViewDelegate(drawable: drawable, commandQueue: commandQueue, pixelFormat: .bgra8Unorm)
        return delegate
    }
    
    func setupView(_ view :MTKView, context:Context) {
        view.delegate = context.coordinator
        view.device = context.coordinator.device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        #if canImport(UIKit)
        view.isOpaque = false
        #else
        view.layer?.isOpaque = false
        #endif
    }
    
    func updateView(_ view: MTKView, context: Context) {
        let delegate = context.coordinator
        let oldDrawable = delegate.drawable as! TaggedDrawable
        if oldDrawable.tag != tag {
            let atlas = try! SpineAtlasBox(path: atlasURL.path)
            
            let shared = try! SpineSkeletonDataBox(atlas: atlas, jsonPath: jsonURL.path)
            let drawable = TaggedDrawable(resource: .init(skeletonData: shared))
            drawable.setTag(tag)
            delegate.drawable = drawable
            if let animationName = self.animationName {
                spAnimationState_setAnimationByName(&drawable.animationState, 0, animationName, 1)
            }
        }

    }
    
}
#if os(macOS)
extension SpineMTKSwiftUIView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> MTKView {
        let someView = MTKView()
        setupView(someView, context: context)
        return someView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        updateView(nsView, context: context)

    }
    
}
#endif

#if os(iOS) || os(visionOS) || os(tvOS)
extension SpineMTKSwiftUIView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> MTKView {
        let someView = MTKView()

        setupView(someView, context: context)
        return someView
    }
    
    func updateUIView(_ nsView: MTKView, context: Context) {
        updateView(nsView, context: context)
        
    }
    
}
#endif
