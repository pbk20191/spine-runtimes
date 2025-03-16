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

public protocol SpineRendererDelegate: AnyObject {

    func spineRenderer(_ renderer: SpineRenderer, willUpdate:CFAbsoluteTime)
    
    func spineRenderer(_ renderer: SpineRenderer, didUpdate:CFAbsoluteTime)
    
    func fetchTexture(_ renderer: SpineRenderer,_ item: TextureIdentifier, _ page: UnsafePointer<spAtlasPage>) -> (any MTLTexture)?
    
    func spineRender(_ renderer: SpineRenderer, minimumSize:Int) -> (any SpineVertexBuffer)?
    
}

@objc
public protocol SpineVertexBuffer: NSObjectProtocol {
    
    /// buffer must be cpu accessible
    var buffer: any MTLBuffer { get }
}


#endif
