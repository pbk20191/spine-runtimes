//
//  File.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import class Foundation.NSMutableDictionary
import spine_c

extension UnsafeMutablePointer where Pointee == spRegionAttachment {
    @inlinable
    var rendererObject: UnsafeMutablePointer<spAtlasRegion> {
        pointee.rendererObject.assumingMemoryBound(to: spAtlasRegion.self)
    }

}

extension UnsafePointer where Pointee == spRegionAttachment {
    @inlinable
    var rendererObject: UnsafeMutablePointer<spAtlasRegion> {
        pointee.rendererObject.assumingMemoryBound(to: spAtlasRegion.self)
    }

}

extension UnsafeMutablePointer where Pointee == spMeshAttachment {
    @inlinable
    var rendererObject: UnsafeMutablePointer<spAtlasRegion> {
        pointee.rendererObject.assumingMemoryBound(to: spAtlasRegion.self)
    }
}

extension UnsafePointer where Pointee == spMeshAttachment {
    @inlinable
    var rendererObject: UnsafeMutablePointer<spAtlasRegion> {
        pointee.rendererObject.assumingMemoryBound(to: spAtlasRegion.self)
    }
}

public extension UnsafeMutablePointer where Pointee == spAtlasPage {
    
    var rendererObject: NSMutableDictionary {
        Unmanaged<NSMutableDictionary>.fromOpaque(pointee.rendererObject).takeUnretainedValue()
    }
    
}

public extension UnsafePointer where Pointee == spAtlasPage {
    
    var rendererObject: NSMutableDictionary {
        Unmanaged<NSMutableDictionary>.fromOpaque(pointee.rendererObject).takeUnretainedValue()
    }
    
}
