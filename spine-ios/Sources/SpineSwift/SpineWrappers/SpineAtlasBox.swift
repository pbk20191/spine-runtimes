//
//  SpineAtlasBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_c
import Foundation

open class SpineAtlasBox: NSObject {
    
    @nonobjc internal let native: UnsafeMutablePointer<spAtlas>
    
    @nonobjc
    public init(atlas: UnsafeMutablePointer<spAtlas>) {
        self.native = atlas
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
    
    @objc public convenience init?(
        path:String,
        rendererObject:UnsafeMutableRawPointer? = nil
    ) {
        if let atlas = spAtlas_createFromFile(path, rendererObject) {
            self.init(atlas: atlas)
        } else {
            return nil
        }
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:)
    public convenience init(notForSwift atlas: UnsafeMutablePointer<spAtlas>) {
        self.init(atlas: atlas)
    }
    
    deinit {
        spAtlas_dispose(native)
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (UnsafeMutablePointer<spAtlas>) -> Void
    ) {
        body(native)
    }
    
    
}

public extension SpineAtlasBox {
    
    func accessAtlas<R:~Copyable, Failure:Error>(
        _ body:  (borrowing PointeeBox<spAtlas>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(.init(native))
    }
    
}
