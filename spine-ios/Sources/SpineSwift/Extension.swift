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

extension UnsafePointer where Pointee == spSkeletonBounds {
    
    func asdf() -> CGPath {
        let path = CGMutablePath()

        let polygonCount = Int(self.pointee.count)
        guard polygonCount > 0 else { return path }

        let polygons = UnsafeBufferPointer(start: self.pointee.polygons, count: polygonCount)

        for polygon in polygons {
            guard let polygon else { continue }

            let vertexCount = Int(polygon.pointee.count)
            guard vertexCount >= 4 else { continue } // 최소 2개 점 이상 필요 (x, y)

            let vertices = UnsafeBufferPointer(start: polygon.pointee.vertices, count: vertexCount)

            // 시작점
            let startX = CGFloat(vertices[0])
            let startY = CGFloat(vertices[1])
            path.move(to: CGPoint(x: startX, y: startY))

            // 나머지 선들 추가
            for i in stride(from: 2, to: vertexCount, by: 2) {
                let x = CGFloat(vertices[i])
                let y = CGFloat(vertices[i + 1])
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // 경로 닫기
            path.closeSubpath()
        }

        return path
    }
    
}
