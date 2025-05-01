//
//  SpineRendererDelegate.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

import Foundation
import spine_c

#if canImport(Metal)
import Metal
@objc
public protocol SpineRendererDelegate {

    func spineRenderer(_ renderer: SpineRenderer, willUpdateAtTime time: CFAbsoluteTime)

    func spineRenderer(_ renderer: SpineRenderer, didUpdateAtTime time: CFAbsoluteTime)

    func spineRenderer(_ renderer: SpineRenderer, textureForPage page: UnsafePointer<spAtlasPage>) -> (any MTLTexture)?

    func spineRenderer(_ renderer: SpineRenderer, vertexBufferForMinimumSize minimumSize: Int, offsetInBytes: UnsafeMutablePointer<Int>) -> (any MTLBuffer)?

    func spineRenderer(_ renderer: SpineRenderer, samplerForPage page: UnsafePointer<spAtlasPage>) -> (any MTLSamplerState)
    
}

extension SpineRendererDelegate {
    
    public func spineRenderer(_ renderer: SpineRenderer, willUpdateAtTime time: CFAbsoluteTime) {}
    
    public func spineRenderer(_ renderer: SpineRenderer, didUpdateAtTime time: CFAbsoluteTime) {}
    
}

@objc
public protocol SpineVertexBuffer {
    
    /// buffer must be cpu accessible
    var buffer: any MTLBuffer { get }
    
    var offsetInBytes:Int { get }
}

extension SpineVertexBuffer {
    
    var offsetInBytes: Int { 0 }
    
}

#endif
