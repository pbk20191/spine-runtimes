
//
//  SpineAtlasBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import spine_cpp
import Foundation

open class SpineAtlasBox: NSObject {

    
    @nonobjc internal let box: PointeeBox<spine.Atlas, Disposer>
    
    struct Disposer: BoxDisposerProtocol {
        static func dispose(_ pointer: UnsafeMutablePointer<spine.Atlas>) {
            pointer.deinitialize(count: 1)
            let k = #file as StaticString
            spine.SpineExtension.free(pointer, k.utf8Start, #line)
        }
        
        typealias Pointee = spine.Atlas
        
        
    }
    
    @nonobjc
    public init(atlas: UnsafeMutablePointer<spine.Atlas>) {
        self.box = .init(atlas)
        super.init()
    }
    
    @objc public convenience init(
        txt:String,
        dirPath:String = ""
    ) {
        let atlas = txt.utf8CString.withUnsafeBufferPointer {
            spine_support.Atlas_load($0.baseAddress, Int32($0.count), dirPath)
        }!
        self.init(atlas: atlas)
    }
    
    @nonobjc public convenience init(
        path:String
    ) {
        let atlas = spine_support.Atlas_load(path)!
        self.init(atlas: atlas)
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithPath:)
    public convenience init(
        notForSwift path:String,
    ) {
        self.init(path: path)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:)
    public convenience init(notForSwift atlas: OpaquePointer) {
        self.init(atlas: .init(atlas))
    }

    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (UnsafeMutableRawPointer) -> Void
    ) {
        withUnsafeMutablePointer(to: &self.box[]) {
            body($0)
        }
    }
    
    @inline(__always)
    @nonobjc
    public subscript() -> spine.Atlas {
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
    
    @nonobjc private var nativePointer:UnsafeMutablePointer<spine.Atlas> {
        self.box._pointer
    }
    
}
