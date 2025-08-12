//
//  SizingInfoOutput.swift
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//


import CoreGraphics
import Foundation
import SpineShadersStructs
//
//  SizingInfoOutput.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import simd

public struct SizingInfoOutput: Hashable, BitwiseCopyable, Sendable {


    struct SpineTransformWrapper: Hashable, BitwiseCopyable, Sendable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard
                lhs.transform.offset == rhs.transform.offset,
                lhs.transform.scale == rhs.transform.scale,
                lhs.transform.translation == rhs.transform.translation
            else { return false }
            return true
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(transform.offset)
            hasher.combine(transform.scale)
            hasher.combine(transform.translation)
        }

        var transform: SpineTransform
    }

    public var size: CGSize
    public var viewPort: CGRect
    internal var transformValue: SpineTransformWrapper

    public var transform: SpineTransform {
        @storageRestrictions(initializes: transformValue)
        init(newValue) {
            transformValue = .init(transform: newValue)
        }
        get { transformValue.transform }
        set { transformValue.transform = newValue }
        _modify { yield &transformValue.transform }
    }

    public init(size: CGSize, viewPort: CGRect, transform: SpineTransform) {
        self.size = size
        self.viewPort = viewPort
        self.transform = transform
    }

}


extension SizingInfoOutput {

    /// Core building blocks for transformation
    private var platformScale: CGSize {
        CGSize(
            width: CGFloat(viewPort.width) / size.width,
            height: CGFloat(viewPort.height) / size.height
        )
    }

    private var platformOffset: CGPoint {
        CGPoint(
            x: viewPort.origin.x,
            y: viewPort.origin.y
        )
    }

    private var logicalScale: CGSize {
        CGSize(
            width: CGFloat(transform.scale.x) / platformScale.width,
            height: CGFloat(transform.scale.y) / platformScale.height
        )
    }

    private var logicalOffset: CGPoint {
        CGPoint(
            x: CGFloat(transform.offset.x) / platformScale.width,
            y: CGFloat(transform.offset.y) / platformScale.height
        )
    }

    private var logicalTranslation: CGPoint {
        CGPoint(
            x: CGFloat(transform.translation.x),
            y: CGFloat(transform.translation.y)
        )
    }

    /// Transform from skeleton (Spine) space to platform (UIKit, SwiftUI) space
    public var toPlatformTransform: CGAffineTransform {
        let s = logicalScale
        let o = logicalOffset
        let t = logicalTranslation
        let p = platformOffset

        let flipY = CGAffineTransform(scaleX: 1, y: 1)
            .concatenating(CGAffineTransform(translationX: size.width / 2.0, y: size.height / 2.0))
        return CGAffineTransform(translationX: p.x, y: p.y)
            .concatenating(CGAffineTransform(translationX: t.x + o.x / s.width, y: t.y + o.y / s.height))
            .concatenating(CGAffineTransform(scaleX: s.width, y: s.height))
            .concatenating(flipY)
    }

    /// Inverse: from platform space back to skeleton (Spine) coordinate space
    public var toSkeletonTransform: CGAffineTransform {
        let s = logicalScale
        let o = logicalOffset
        let t = logicalTranslation
        let p = platformOffset

        // 1. flipY의 역변환
        let flipYInverse = CGAffineTransform(translationX: -size.width / 2.0, y: -size.height / 2.0)
            .concatenating(CGAffineTransform(scaleX: 1, y: 1))

        // 2. scale의 역변환
        let scaleInverse = CGAffineTransform(scaleX: 1 / s.width, y: 1 / s.height)

        // 3. offset + translation의 역변환
        let offsetTranslationInverse = CGAffineTransform(
            translationX: -(t.x + o.x / s.width),
            y: -(t.y + o.y / s.height)
        )

        // 4. platformOffset의 역변환
        let platformOffsetInverse = CGAffineTransform(
            translationX: -p.x,
            y: -p.y
        )

        return
            flipYInverse
            .concatenating(scaleInverse)
            .concatenating(offsetTranslationInverse)
            .concatenating(platformOffsetInverse)
    }
}
