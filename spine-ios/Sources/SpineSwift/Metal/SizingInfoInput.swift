//
//  SizingInfoInput.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import CoreGraphics

public struct SizingInfoInput: Hashable, BitwiseCopyable {
    
    public var spineNativeBound:CGRect
    public var contentMode:ContentMode
    public var alignment:Alignment
    public var displaySize:CGSize
    public var displayScale:CGFloat

    public var displayPixelSize:CGSize {
        displaySize.applying(.init(scaleX: displayScale, y: displayScale))
    }
    
    public init(spineNativeBound: CGRect, contentMode: ContentMode, alignment: Alignment, displaySize: CGSize, displayScale: CGFloat) {
        self.spineNativeBound = spineNativeBound
        self.contentMode = contentMode
        self.alignment = alignment
        self.displaySize = displaySize
        self.displayScale = displayScale
    }
    
    func generateOutput() -> SizingInfoOutput {
        SizingInfoOutput.translateSize(textureSize: displayPixelSize, contentScale: displayScale, boundOfDrawable: spineNativeBound, alignment: alignment, contentMode: contentMode)
    }
}


