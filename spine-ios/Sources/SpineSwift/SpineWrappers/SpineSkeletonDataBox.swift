//
//  SpineSkeletonDataBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import Foundation
import spine_c

open class SpineSkeletonDataBox: NSObject {
        
    @usableFromInline
    struct Cleanup: BoxDisposerProtocol {
        
        @usableFromInline
        static func dispose(_ pointer: UnsafeMutablePointer<spSkeletonData>) {
            spSkeletonData_dispose(pointer)
        }
        
    }
    
    @usableFromInline
    typealias Box = PointeeBox<spSkeletonData, Cleanup>
    
    @nonobjc
    internal let pAtlas: SpineAtlasBox
    @nonobjc
    internal let box: Box
    
    @nonobjc
    private var nativePointer: UnsafeMutablePointer<spSkeletonData> {
        self.box._pointer
    }
    
    // expects skeletonData is created from the given atlas
    @nonobjc
    public init(
        atlas: SpineAtlasBox,
        skeletonData: UnsafeMutablePointer<spSkeletonData>
    ) {
        self.pAtlas = atlas
        self.box = .init(skeletonData)
        super.init()
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skeletonData:)
    public convenience init(
        invalidForSwift atlas:SpineAtlasBox,
        invalidForSwift skeletonData:UnsafeMutablePointer<spSkeletonData>
    ) {
        self.init(atlas: atlas, skeletonData: skeletonData)
    }
    
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        json:String
    ) throws(SpineParsingError) {
        let reader = spSkeletonJson_create(&atlas[])!
        defer {
            spSkeletonJson_dispose(reader)
        }
        let dataBlock = spSkeletonJson_readSkeletonData(reader, json)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            throw SpineParsingError(String(cString: reader.pointee.error))
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        jsonPath:String
    ) throws(SpineParsingError) {
        let reader = spSkeletonJson_create(&atlas[])!
        defer {
            spSkeletonJson_dispose(reader)
        }
        let dataBlock = spSkeletonJson_readSkeletonDataFile(reader, jsonPath)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            throw SpineParsingError(String(cString: reader.pointee.error))
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        binary:Data
    ) throws(SpineParsingError) {
        let reader = spSkeletonBinary_create(&atlas[])!
        defer {
            spSkeletonBinary_dispose(reader)
        }
        let dataBlock = binary.withUnsafeBytes {
            spSkeletonBinary_readSkeletonData(reader, $0.baseAddress, Int32($0.count))
        }
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            throw SpineParsingError(String(cString: reader.pointee.error))
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode
    @nonobjc public convenience init(
        atlas:SpineAtlasBox,
        skelPath:String
    ) throws(SpineParsingError) {
        let reader = spSkeletonBinary_create(&atlas[])!
        defer {
            spSkeletonBinary_dispose(reader)
        }
        let dataBlock = spSkeletonBinary_readSkeletonDataFile(reader, skelPath)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: dataBlock)
        } else {
            throw SpineParsingError(String(cString: reader.pointee.error))
        }
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
        try self.init(atlas: atlas, jsonPath: skelPath)
    }

    @objc
    open var atlas: SpineAtlasBox { pAtlas }
        
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutablePointer<spSkeletonData>) -> Void
    ) {
        body(&box[])
    }
    
    @nonobjc
    @inline(__always)
    public subscript() -> spSkeletonData {
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
