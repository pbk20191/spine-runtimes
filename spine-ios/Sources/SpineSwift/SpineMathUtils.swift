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
        textureSize: CGSize,
        contentScale: CGFloat,
        boundOfDrawable: CGRect,
        alignment: Alignment,
        contentMode: ContentMode
    ) -> SizingInfoOutput {
        let sizeInPoints = CGSize(width: textureSize.width / contentScale, height: textureSize.height / contentScale)
        let viewPortSize = SIMD2<UInt32>(UInt32(textureSize.width), UInt32(textureSize.height))
        
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
        
        return .init(size: sizeInPoints, viewPort: viewPortSize, transform: transform)
    }


    public static func transformPath(
        sourceRect: CGRect,
        alignment: Alignment,
        contentMode: ContentMode,
        destinationRect: CGRect,
        biasRect:CGRect? = nil
    ) -> CGAffineTransform {
        if sourceRect.isNull {
            return .identity
        }
        // 1. sourceRect의 크기와 origin 고려
        let sourceSize = biasRect?.size ?? sourceRect.size
        let sourceOrigin = biasRect?.origin ?? sourceRect.origin

        // 2. 스케일 계산
        let scaleX = destinationRect.width / sourceSize.width
        let scaleY = destinationRect.height / sourceSize.height

        let scale: CGFloat
        switch contentMode {
        case .fit:
            scale = min(scaleX, scaleY)
        case .fill:
            scale = max(scaleX, scaleY)
        }

        let scaledSize = CGSize(width: sourceSize.width * scale,
                                height: sourceSize.height * scale)

        // 3. 정렬 anchor 계산 (-1 ~ 1 → 0 ~ 1 보간)
        let anchorX = (alignment.x + 1) / 2
        let anchorY = (alignment.y + 1) / 2

        // 4. source의 anchor 기준점 위치 (스케일 전 기준)
        let sourceAnchor = CGPoint(
            x: sourceOrigin.x + sourceSize.width * anchorX,
            y: sourceOrigin.y + sourceSize.height * anchorY
        )

        // 5. destination의 anchor 기준 위치
        let destinationAnchor = CGPoint(
            x: destinationRect.origin.x + destinationRect.width * anchorX,
            y: destinationRect.origin.y + destinationRect.height * anchorY
        )

        // 6. 변환 계산
        // 6-1. 기준점 → 원점
        let moveAnchorToOrigin = CGAffineTransform(translationX: -sourceAnchor.x, y: -sourceAnchor.y)

        // 6-2. 스케일
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)

        // 6-3. 원점 → destination의 anchor 위치로
        let moveToTarget = CGAffineTransform(translationX: destinationAnchor.x, y: destinationAnchor.y)

        let final = [
            moveAnchorToOrigin,
            CGAffineTransform(scaleX: 1, y: 1),
            scaleTransform,
            moveToTarget,
            
        ].reduce(into: CGAffineTransform.identity) { partialResult, next in
            // 5. 최종 Transform = scale → translation → offset

            partialResult = partialResult.concatenating(next)
        }

        return final
    }
    
    
}
