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
    
    @nonobjc public convenience init(
        path:String,
        rendererObject:UnsafeMutableRawPointer? = nil
    ) throws(SpineParsingError) {
        if let atlas = spAtlas_createFromFile(path, rendererObject) {
            self.init(atlas: atlas)
        } else {
            throw SpineParsingError("Failed to load atlas file: \(path)")
        }
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithPath:rendererObject:error:)
    public convenience init(
        notForSwift path:String,
        rendererObject:UnsafeMutableRawPointer? = nil
    ) throws {
        try self.init(path: path, rendererObject: rendererObject)
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
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return self.nativePointer == other.nativePointer
    }
    
    open override var hash: Int {
        return self.nativePointer.hashValue
    }
    
}
