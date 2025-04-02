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
        let textureKey = "KSPTexture"
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


struct SpineMTKSwiftUIView: Equatable {
    
    let atlasURL: URL
    let jsonURL: URL
    let animationName: String?
    
    func makeCoordinator() -> SpineViewDelegate {
//        let atlasURL = Bundle.main.url(forResource: "coin-pma", withExtension: "atlas")!
//        let jsonURL = Bundle.main.url(forResource: "coin-pro", withExtension: "json")!
    
        let atlasTxt = try! String.init(contentsOf: atlasURL, encoding: .utf8)
        let jsonTxt = try! String.init(contentsOf: jsonURL, encoding: .utf8)
        let atlas = try! SpineResourceHandle.parseAndCreateAtlas(atlasTxt: atlasTxt, rendererObject: nil).get()
        let skelData = try! SpineResourceHandle.parseAndCreateData(jsonTxt: jsonTxt, atlas: atlas).get()
        let shared = SpineAnimationStateDataBox(skeletonData: skelData)
        let drawable = SpineSwiftDrawable(resource: shared)
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()!
        let delegate = try! SpineViewDelegate(drawable: drawable, commandQueue: commandQueue, pixelFormat: .bgra8Unorm)
        return delegate
    }
    
    func updateView(_ view: MTKView, context: Context) {
        let delegate = context.coordinator
        let atlasTxt = try! String.init(contentsOf: atlasURL, encoding: .utf8)
        let jsonTxt = try! String.init(contentsOf: jsonURL, encoding: .utf8)
        let atlas = try! SpineResourceHandle.parseAndCreateAtlas(atlasTxt: atlasTxt, rendererObject: nil).get()
        let skelData = try! SpineResourceHandle.parseAndCreateData(jsonTxt: jsonTxt, atlas: atlas).get()
        let shared = SpineAnimationStateDataBox(skeletonData: skelData)
        let drawable = SpineSwiftDrawable(resource: shared)
        delegate.drawable = drawable
        let animationName = self.animationName
        drawable.accessAnimation {
            let _ = spAnimationState_setAnimationByName(&$0, 0, animationName, 1)
        }
    }
    
}
#if os(macOS)
extension SpineMTKSwiftUIView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> MTKView {
        let someView = MTKView()
        context.coordinator.boundsProvider = SetupPoseBounds()
        someView.delegate = context.coordinator
        someView.device = context.coordinator.device
        someView.colorPixelFormat = .bgra8Unorm
//
//        context.coordinator.drawable.accessSkeleton {
//            let _ = spSkeleton_setSkinByName(&$0, "Normal")
//        }

        someView.layer?.isOpaque = false
        someView.clearColor = MTLClearColorMake(0, 0, 0, 0)
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
        someView.delegate = context.coordinator
        someView.device = context.coordinator.device
        someView.colorPixelFormat = .bgra8Unorm
        someView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        someView.isOpaque = false
        return someView
    }
    
    func updateUIView(_ nsView: MTKView, context: Context) {
        updateView(nsView, context: context)
        
    }
    
}
#endif
