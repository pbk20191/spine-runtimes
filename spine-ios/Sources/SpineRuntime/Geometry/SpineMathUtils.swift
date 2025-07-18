import CoreGraphics
//
//  SpineMathUtils.swift
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//
import Foundation
import SpineShadersStructs

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
            vector.dy.negate()
        case .fill:
            scaleX = sizeInPoints.width / boundOfDrawable.width
            scaleY = sizeInPoints.height / boundOfDrawable.height
        case .aspectFill:
            scaleX = max(sizeInPoints.width / boundOfDrawable.width, sizeInPoints.height / boundOfDrawable.height)
            scaleY = scaleX
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


    /// calculate a `CGAffineTransform` that transforms the sourceRect to fit the destinationRect according to the alignment and contentMode.
    /// This function is useful for transforming paths or rectangles in a way that respects the drawable's alignment and content mode. so that the user can attach custom drawing over the spine coordinate system.
    /// - Parameters:
    ///   - sourceRect: source rectangle that will be transformed usally path.boundedPath or path.boundingBox
    ///   - alignment: alignment of the sourceRect, which is usually the anchor point of the drawable
    ///   - contentMode: content mode of the drawable, which determines how the sourceRect is transformed to fit the destinationRect
    ///   - destinationRect: destination rectangle where the sourceRect will be transformed to fit
    ///   - biasRect: usally pass the bounds computed by `SkeletonBoundsProvider`, which is used to adjust the sourceRect
    /// - Returns: a `CGAffineTransform` that transforms the sourceRect to fit the destinationRect according to the alignment and contentMode.
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
        var vector = CGVector(dx: alignment.x, dy: alignment.y)

        switch contentMode {
        case .fit:
            let scaleValue = min(scaleX, scaleY)
            scale = [scaleValue, scaleValue]
            vector.dy.negate()  // Adjust for vertical alignment
        case .aspectFill:
            let scaleValue = max(scaleX, scaleY)
            scale = [scaleValue, scaleValue]
            vector.dy.negate()  // Adjust for horizontal alignment
        case .fill:
            scale = [scaleX, scaleY]
        }

        // 3. Calculate normalized anchor point (alignment range: -1 to 1 → convert to 0 to 1)
        let anchorX = (vector.dx + 1) / 2
        let anchorY = (vector.dy + 1) / 2

        // 4. Compute anchor point in sourceRect (before scaling)
        let sourceAnchor = CGPoint(
            x: sourceOrigin.x + sourceSize.width * anchorX,
            y: sourceOrigin.y + sourceSize.height * anchorY
        )

        // 5. Compute anchor point in destinationRect
        let destinationAnchor = CGPoint(
            x: destinationRect.origin.x + destinationRect.width * anchorX,
            y: destinationRect.origin.y + destinationRect.height * (1.0 - anchorY)  // flip
        )

        // 6. Construct final transform

        // 6-1. Move source anchor point to origin
        let moveAnchorToOrigin = CGAffineTransform(translationX: -sourceAnchor.x, y: -sourceAnchor.y)

        // 6-2. Apply scaling
        let scaleTransform = CGAffineTransform(scaleX: scale.x, y: -scale.y)

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
}
