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
        let scaleX = destinationRect.width / sourceSize.width
        let scaleY = destinationRect.height / sourceSize.height

        // Choose scale factor based on contentMode (.fit or .fill)
        let scale: CGFloat
        switch contentMode {
        case .fit:
            scale = min(scaleX, scaleY)
        case .fill:
            scale = max(scaleX, scaleY)
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
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)

        // 6-3. Move to destination anchor point
        let moveToTarget = CGAffineTransform(translationX: destinationAnchor.x, y: destinationAnchor.y)

        // 7. Combine transforms in order: move to origin → scale → move to destination
        let final = [
            moveAnchorToOrigin,
            CGAffineTransform(scaleX: 1, y: 1), // This line seems redundant; no-op scaling
            scaleTransform,
            moveToTarget,
        ].reduce(into: CGAffineTransform.identity) { partialResult, next in
            partialResult = partialResult.concatenating(next)
        }

        return final
    }

    
    
}
