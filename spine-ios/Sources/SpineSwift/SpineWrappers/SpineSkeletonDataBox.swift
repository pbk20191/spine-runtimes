//
//  SpineSkeletonDataBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import Foundation
import spine_cpp

open class SpineSkeletonDataBox: NSObject {
        
    @usableFromInline
    struct Cleanup: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spine.SkeletonData>) {
            pointer.deinitialize(count: 1)
            let k = #file as StaticString
            spine.SpineExtension.free(pointer, k.utf8Start, #line)
        }
        
    }
    
    @usableFromInline
    typealias Box = PointeeBox<spine.SkeletonData, Cleanup>
    
    @nonobjc
    internal let pAtlas: SpineAtlasBox
    @nonobjc
    internal let box: Box
    
    @nonobjc
    private var nativePointer: UnsafeMutablePointer<spine.SkeletonData> {
        self.box._pointer
    }
    
    // expects skeletonData is created from the given atlas
    @nonobjc
    public init(
        atlas: SpineAtlasBox,
        skeletonData: UnsafeMutablePointer<spine.SkeletonData>
    ) {
        self.pAtlas = atlas
        self.box = .init(skeletonData)
        super.init()
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skeletonData:)
    public convenience init(
        invalidForSwift atlas:SpineAtlasBox,
        invalidForSwift skeletonData:OpaquePointer
    ) {
        self.init(atlas: atlas, skeletonData: .init(skeletonData))
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:json:scale:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        json:String,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, json: json, scale: scale)
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:jsonPath:scale:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        jsonPath:String,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, jsonPath: jsonPath, scale: scale)
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:binary:scale:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        binary:Data,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, binary: binary, scale: scale)
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skelPath:scale:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        skelPath:String,
        scale:Float = 1
    ) throws {
        try self.init(atlas: atlas, skelPath: skelPath, scale: scale)
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:json:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        json:String
    ) throws {
        try self.init(atlas: atlas, json: json)
    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:jsonPath:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        jsonPath:String
    ) throws {
        try self.init(atlas: atlas, jsonPath: jsonPath)
    }
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:binary:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        binary:Data
    ) throws {
        try self.init(atlas: atlas, binary: binary)

    }
    
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skelPath:error:)
    public convenience init(
        notForSwift atlas:SpineAtlasBox,
        skelPath:String
    ) throws {
        try self.init(atlas: atlas, skelPath: skelPath)
    }

    @objc
    open var atlas: SpineAtlasBox { pAtlas }
        
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutableRawPointer) -> Void
    ) {
        withUnsafeMutablePointer(to: &self[]) {
            body($0)
        }
    }
    
    @nonobjc
    @inline(__always)
    public subscript() -> spine.SkeletonData {
        @inline(__always)
        borrowing _modify {
            yield &self.box[]
        }
        @inline(__always)
        borrowing _read {
            yield self.box[]
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
    
}

extension SpineSkeletonDataBox {
    
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        json:String,
        scale: Float = 1
    ) throws(SpineParsingError) {
        var reader = spine.SkeletonJson(&atlas[])
        reader.setScale(scale)
        let dataBlock = spine_support.json_readSkeletonData(&reader, json)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            let error = spine_support.json_getError(&reader)
            let message = String(cString: spine_support.peek_String(&error.pointee))
            throw SpineParsingError(message)
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        jsonPath:String,
        scale: Float = 1
    ) throws(SpineParsingError) {
        var reader = spine.SkeletonJson(&atlas[])
        reader.setScale(scale)
 
        let dataBlock: UnsafeMutablePointer<spine.SkeletonData>? = spine_support.json_readSkeletonDataFile(&reader, jsonPath)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            let error = spine_support.json_getError(&reader)
            let message = String(cString: spine_support.peek_String(&error.pointee))
            throw SpineParsingError(message)
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        binary:Data,
        scale: Float = 1
    ) throws(SpineParsingError) {
        var reader = spine.SkeletonBinary(&atlas[])
        reader.setScale(scale)

        let dataBlock = binary.withUnsafeBytes {
            spine_support.binary_readSkeletonData(&reader, $0.baseAddress, Int32($0.count))
        }
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            let error = spine_support.binary_getError(&reader)
            let message = String(cString: spine_support.peek_String(&error.pointee))
            throw SpineParsingError(message)
        }
    }
    
    // typed Throw is unavailbe for objc interface using library evolution mode
    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        skelPath:String,
        scale: Float = 1
    ) throws(SpineParsingError) {
        var reader = spine.SkeletonBinary(&atlas[])
        reader.setScale(scale)

        let dataBlock = spine_support.binary_readSkeletonDataFile(&reader, skelPath)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            let error = spine_support.binary_getError(&reader)
            let message = String(cString: spine_support.peek_String(&error.pointee))
            throw SpineParsingError(message)
        }
    }
    
}
