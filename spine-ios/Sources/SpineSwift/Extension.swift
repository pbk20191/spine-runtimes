//
//  File.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import class Foundation.NSMutableDictionary
import spine_c
import CoreGraphics

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

extension spSkeletonBounds {

    public func computePolygonsPath() -> CGPath {
        let path = CGMutablePath()

        let polygonCount = Int(self.count)
        guard polygonCount > 0 else { return path }

        let polygons = UnsafeBufferPointer(start: self.polygons, count: polygonCount)

        for polygon in polygons {
            guard let polygon else { continue }

            let vertexCount = Int(polygon.pointee.count)
            guard vertexCount >= 4 else { continue } // At least 2 points (4 floats for x and y)

            let vertices = UnsafeBufferPointer(start: polygon.pointee.vertices, count: vertexCount)

            // Move to the starting point of the polygon
            let startX = CGFloat(vertices[0])
            let startY = CGFloat(vertices[1])
            path.move(to: CGPoint(x: startX, y: startY))

            // Add lines for each vertex pair (x, y)
            for i in stride(from: 2, to: vertexCount, by: 2) {
                let x = CGFloat(vertices[i])
                let y = CGFloat(vertices[i + 1])
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // Close the current polygon path
            path.closeSubpath()
        }

        return path.copy()!
    }

}

extension Dictionary {

    @inline(__always)
    @usableFromInline
    internal subscript(_ key:Key, safe block : @autoclosure () -> Value) -> Value {
        mutating get {
            if let value = self[key] { return value }
            let newValue = block()
            self[key] = newValue
            return newValue
        }
    }
    
}

extension Dictionary {

    @inline(__always)
    @usableFromInline
    internal subscript(_ key:Key, safe2 block : @autoclosure () -> Value?) -> Value? {
        mutating get {
            if let value = self[key] { return value }
            if let newValue = block() {
                self[key] = newValue
                return newValue
            }
            return nil
        }
    }
    
}
