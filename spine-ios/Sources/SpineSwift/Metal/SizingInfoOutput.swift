//
//  SizingInfoOutput.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import simd
import SpineShadersStructs
import CoreGraphics

struct SizingInfoOutput: Hashable, BitwiseCopyable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.size == rhs.size else { return false }
        guard lhs.viewPort == rhs.viewPort else { return false }
        guard
            lhs.transform.offset == rhs.transform.offset,
            lhs.transform.scale == rhs.transform.scale,
            lhs.transform.translation == rhs.transform.translation
        else { return false }
        return true
    }
    
    var size:CGSize
    var viewPort:SIMD2<UInt32>
    var transform:SpineTransform
    
    
    func hash(into hasher: inout Hasher) {
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, visionOS 2.0, watchOS 11.0, *) {
            hasher.combine(size)
        } else {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }
        hasher.combine(viewPort)
        hasher.combine(transform.offset)
        hasher.combine(transform.scale)
        hasher.combine(transform.translation)
    }
    
    static func translateSize(
        textureSize:CGSize,
        contentScale:CGFloat,
        boundOfDrawable:CGRect,
        alignment: Alignment,
        contentMode: ContentMode
    ) -> SizingInfoOutput {
        let sizeInPoints = CGSize(width: textureSize.width / contentScale, height: textureSize.height / contentScale)
        let viewPortSize = SIMD2<UInt32>(UInt32(textureSize.width), UInt32(textureSize.height))
        
        let x = -boundOfDrawable.minX - boundOfDrawable.width / 2.0
        let y = -boundOfDrawable.minY - boundOfDrawable.height / 2.0
        
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        
        switch contentMode {
        case .fit:
            scaleX = min(sizeInPoints.width / boundOfDrawable.width, sizeInPoints.height / boundOfDrawable.height)
            scaleY = scaleX
        case .fill:
            scaleX = max(sizeInPoints.width / boundOfDrawable.width, sizeInPoints.height / boundOfDrawable.height)
            scaleY = scaleX
        }
        
        let offsetX = abs(sizeInPoints.width - boundOfDrawable.width * scaleX) / 2 * alignment.x
        let offsetY = abs(sizeInPoints.height - boundOfDrawable.height * scaleY) / 2 * alignment.y
        let transform = SpineTransform(
            translation: SIMD2<Float>(.init(x), .init(y)),
            scale: SIMD2<Float>(.init(scaleX * contentScale), .init(scaleY * contentScale)),
            offset: SIMD2<Float>(.init(offsetX * contentScale), .init(offsetY * contentScale))
        )
        
        return .init(size: sizeInPoints, viewPort: viewPortSize, transform: transform)
    }


    
}
    
