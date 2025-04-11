//
//  SpineAtlasBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_c
import Foundation

open class SpineAtlasBox: NSObject {
    
    @nonobjc internal let nativePointer: UnsafeMutablePointer<spAtlas>
    
    @nonobjc
    public init(atlas: UnsafeMutablePointer<spAtlas>) {
        self.nativePointer = atlas
        super.init()
    }
    
    @objc public convenience init(
        txt:String,
        dirPath:String = "",
        rendererObject:UnsafeMutableRawPointer? = nil
    ) {
        let atlas = txt.utf8CString.withUnsafeBufferPointer {
            spAtlas_create($0.baseAddress!, Int32($0.count), dirPath, rendererObject)!
        }
        self.init(atlas: atlas)
    }
    
    @objc public convenience init(
        path:String,
        rendererObject:UnsafeMutableRawPointer? = nil
    ) throws(SpineParsingError) {
        if let atlas = spAtlas_createFromFile(path, rendererObject) {
            self.init(atlas: atlas)
        } else {
            throw SpineParsingError("Failed to load atlas file: \(path)")
        }
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:)
    public convenience init(notForSwift atlas: UnsafeMutablePointer<spAtlas>) {
        self.init(atlas: atlas)
    }
    
    deinit {
        spAtlas_dispose(nativePointer)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (UnsafeMutablePointer<spAtlas>) -> Void
    ) {
        body(nativePointer)
    }
    
    @nonobjc
    public subscript() -> spAtlas {
        unsafeAddress {
            UnsafePointer(nativePointer)
        }
        unsafeMutableAddress { nativePointer }
    }
    
}
