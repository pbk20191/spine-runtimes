//
//  SpineAtlasBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_c
import Foundation

open class SpineAtlasBox: NSObject {
    
    @usableFromInline
    struct Cleanup: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spAtlas>) {
            spAtlas_dispose(pointer)
        }
        
    }
    
    @usableFromInline
    typealias Box = PointeeBox<spAtlas, Cleanup>
    
    @nonobjc internal let box: Box
    
    @nonobjc
    public init(atlas: UnsafeMutablePointer<spAtlas>) {
        self.box = .init(atlas)
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

    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (UnsafeMutablePointer<spAtlas>) -> Void
    ) {
        body(&box[])
    }
    
    @inline(__always)
    @nonobjc
    public subscript() -> spAtlas {
        @inline(__always)
        borrowing _modify {
            yield &box[]
        }
        @inline(__always)
        borrowing _read {
            yield box[]
        }
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
    
    @nonobjc private var nativePointer:UnsafeMutablePointer<spAtlas> {
        self.box._pointer
    }
    
}
