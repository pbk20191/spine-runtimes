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

@objcMembers
public final class SpineMathUtils: NSObject {
    
    
    @nonobjc
    private override init() {
        super.init()
    }
    
    
    private struct InternalSizing {
        var scaleX: CGFloat
        var scaleY: CGFloat
        var offsetX: CGFloat
        var offsetY: CGFloat
        var translation: CGPoint
        var sizeInPoints: CGSize
    }
    
    private static func computeInternalSizing(
        textureSize: CGSize,
        contentScale: CGFloat,
        bound: CGRect,
        alignment: Alignment,
        contentMode: ContentMode
    ) -> InternalSizing {
        let sizeInPoints = CGSize(width: textureSize.width / contentScale, height: textureSize.height / contentScale)

        let x = -bound.minX - bound.width / 2
        let y = -bound.minY - bound.height / 2

        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0

        switch contentMode {
        case .fit:
            scaleX = min(sizeInPoints.width / bound.width, sizeInPoints.height / bound.height)
            scaleY = scaleX
        case .fill:
            scaleX = max(sizeInPoints.width / bound.width, sizeInPoints.height / bound.height)
            scaleY = scaleX
        }

        let offsetX = abs(sizeInPoints.width - bound.width * scaleX) / 2 * alignment.x
        let offsetY = abs(sizeInPoints.height - bound.height * scaleY) / 2 * alignment.y

        return InternalSizing(
            scaleX: scaleX * contentScale,
            scaleY: scaleY * contentScale,
            offsetX: offsetX * contentScale,
            offsetY: offsetY * contentScale,
            translation: CGPoint(x: x, y: y),
            sizeInPoints: sizeInPoints
        )
    }

    
    public static func translateSize(
        textureSize: CGSize,
        contentScale: CGFloat,
        boundOfDrawable: CGRect,
        alignment: Alignment,
        contentMode: ContentMode
    ) -> SizingInfoOutput {
        let sizing = computeInternalSizing(
            textureSize: textureSize,
            contentScale: contentScale,
            bound: boundOfDrawable,
            alignment: alignment,
            contentMode: contentMode
        )

        let transform = SpineTransform(
            translation: SIMD2<Float>(Float(sizing.translation.x), Float(sizing.translation.y)),
            scale: SIMD2<Float>(Float(sizing.scaleX), Float(sizing.scaleY)),
            offset: SIMD2<Float>(Float(sizing.offsetX), Float(sizing.offsetY))
        )

        return SizingInfoOutput(
            size: sizing.sizeInPoints,
            viewPort: SIMD2<UInt32>(UInt32(textureSize.width), UInt32(textureSize.height)),
            transform: transform
        )
    }


    public static func transformPath(
        sourceRect: CGRect,
        alignment: Alignment,
        contentMode: ContentMode,
        destinationRect: CGRect
    ) -> CGAffineTransform {
        guard !sourceRect.isNull else {
            return .identity
        }

        let textureSize = destinationRect.size.applying(.init(scaleX: 1, y: 1))
        let contentScale: CGFloat = 1.0 // 또는 필요한 경우 외부 인자로 받기

        let sizing = computeInternalSizing(
            textureSize: textureSize,
            contentScale: contentScale,
            bound: sourceRect,
            alignment: alignment,
            contentMode: contentMode
        )

        // CGAffineTransform(translation) → scale → translation
        return CGAffineTransform(translationX: -sourceRect.origin.x, y: -sourceRect.origin.y)
            .scaledBy(x: sizing.scaleX, y: sizing.scaleY)
            .translatedBy(x: destinationRect.origin.x + sizing.offsetX,
                          y: destinationRect.origin.y + sizing.offsetY)
    }
    
    
}
