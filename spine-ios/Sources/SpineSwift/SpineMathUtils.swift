//
//  SpineMathUtils.swift
//  spine-ios
//
//  Created by 박병관 on 3/23/25.
//

import spine_c
import SpineShadersStructs
import CoreGraphics
import simd
import Foundation


public final class SpineMathUtils: NSObject {
    
    
    @nonobjc
    private override init() {
        super.init()
    }

    
    public static func translateSize(
        textureBoundInPoint: CGRect,
        contentScale: CGFloat,
        boundOfDrawable: CGRect,
        alignment: Alignment,
        contentMode: ContentMode
    ) -> SizingInfoOutput {
        let sizeInPoints = textureBoundInPoint.size
        let viewPort = textureBoundInPoint.applying(.init(scaleX: contentScale, y: contentScale))
        
        let x = -boundOfDrawable.minX - boundOfDrawable.width / 2.0
        let y = -boundOfDrawable.minY - boundOfDrawable.height / 2.0
        
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        var vector = CGVector(dx: alignment.x, dy: alignment.y)
        switch contentMode {
        case .fit:
            scaleX = min(sizeInPoints.width / boundOfDrawable.width, sizeInPoints.height / boundOfDrawable.height)
            scaleY = scaleX
        case .fill:
            scaleX = sizeInPoints.width / boundOfDrawable.width
            scaleY = sizeInPoints.height / boundOfDrawable.height
        case .aspectFill:
            scaleX = max(sizeInPoints.width / boundOfDrawable.width, sizeInPoints.height / boundOfDrawable.height)
            scaleY = scaleX
            vector.dy.negate()
            vector.dx.negate()
        }
        let offsetX = abs(sizeInPoints.width - boundOfDrawable.width * scaleX) * vector.dx / 2
        let offsetY = abs(sizeInPoints.height - boundOfDrawable.height * scaleY) * vector.dy / 2
        let transform = SpineTransform(
            translation: SIMD2<Float>(.init(x), .init(y)),
            scale: SIMD2<Float>(.init(scaleX * contentScale), .init(scaleY * contentScale)),
            offset: SIMD2<Float>(.init(offsetX * contentScale), .init(offsetY * contentScale))
        )
        
        return .init(size: sizeInPoints, viewPort: viewPort, transform: transform)
    }


    public static func transformPath(
        sourceRect: CGRect,
        alignment: Alignment,
        contentMode: ContentMode,
        destinationRect: CGRect,
        biasRect: CGRect? = nil
    ) -> CGAffineTransform {
        
        // Return identity if sourceRect is invalid
        if sourceRect.isNull {
            return .identity
        }

        // 1. Determine the size and origin of the source rectangle
        // If biasRect is provided, use its values instead
        let sourceSize = biasRect?.size ?? sourceRect.size
        let sourceOrigin = biasRect?.origin ?? sourceRect.origin

        // 2. Compute scale factors based on destination size
        let scaleX = sourceSize.width.isNormal ? destinationRect.width / sourceSize.width : 0
        let scaleY = sourceSize.height.isNormal ? destinationRect.height / sourceSize.height : 0

        // Choose scale factor based on contentMode (.fit or .fill)
        let scale: SIMD2<Double>
        switch contentMode {
        case .fit:
            let scaleValue = min(scaleX, scaleY)
            scale = [scaleValue, scaleValue]
        case .aspectFill:
            let scaleValue = max(scaleX, scaleY)
            scale = [scaleValue, scaleValue]
        case .fill:
            scale = [ scaleX, scaleY ]
        }

        // 3. Calculate normalized anchor point (alignment range: -1 to 1 → convert to 0 to 1)
        let anchorX = (alignment.x + 1) / 2
        let anchorY = (alignment.y + 1) / 2

        // 4. Compute anchor point in sourceRect (before scaling)
        let sourceAnchor = CGPoint(
            x: sourceOrigin.x + sourceSize.width * anchorX,
            y: sourceOrigin.y + sourceSize.height * anchorY
        )

        // 5. Compute anchor point in destinationRect
        let destinationAnchor = CGPoint(
            x: destinationRect.origin.x + destinationRect.width * anchorX,
            y: destinationRect.origin.y + destinationRect.height * anchorY
        )

        // 6. Construct final transform

        // 6-1. Move source anchor point to origin
        let moveAnchorToOrigin = CGAffineTransform(translationX: -sourceAnchor.x, y: -sourceAnchor.y)

        // 6-2. Apply scaling
        let scaleTransform = CGAffineTransform(scaleX: scale.x, y: scale.y)

        // 6-3. Move to destination anchor point
        let moveToTarget = CGAffineTransform(translationX: destinationAnchor.x, y: destinationAnchor.y)

        // 7. Combine transforms in order: move to origin → scale → move to destination
        let final = [
            moveAnchorToOrigin,
            scaleTransform,
            moveToTarget,
        ].reduce(into: CGAffineTransform.identity) { partialResult, next in
            partialResult = partialResult.concatenating(next)
        }

        return final
    }

    @objc
    public static func measureBound(
        
        _ skeleton: UnsafeMutablePointer<spSkeleton>,
        _ clipper: UnsafeMutablePointer<spSkeletonClipping>?
    ) -> CGPath {
        
        let path = CGMutablePath()
        spSkeleton_render(skeleton, clipper, { blockPtr, ref in
            let mutable = Unmanaged<CGMutablePath>.fromOpaque(ref!).takeUnretainedValue()
            let indexBuffer = UnsafeBufferPointer(start: blockPtr.pointee.indices, count: blockPtr.pointee.indexCount)
            let vertexBuffer = UnsafeBufferPointer(start: blockPtr.pointee.positions, count: blockPtr.pointee.positionCount)
            for t in stride(from: 0, to: blockPtr.pointee.indexCount, by: 3) {
                let i0 = Int(indexBuffer[t] * 2)
                let i1 = Int(indexBuffer[t + 1] * 2)
                let i2 = Int(indexBuffer[t + 2] * 2)
                let p0 = CGPoint(
                    x: Double(vertexBuffer[i0]),
                    y: Double(vertexBuffer[i0 + 1])
                )
                let p1 = CGPoint(
                    x: Double(vertexBuffer[i1]),
                    y: Double(vertexBuffer[i1 + 1])
                )
                let p2 = CGPoint(
                    x: Double(vertexBuffer[i2]),
                    y: Double(vertexBuffer[i2 + 1])
                )
                mutable.move(to: p0)
                mutable.addLine(to: p1)
                mutable.addLine(to: p2)
                mutable.closeSubpath()
            }
            
        }, Unmanaged<CGPath>.passUnretained(path).toOpaque())
        return path
    }
    
    
}
