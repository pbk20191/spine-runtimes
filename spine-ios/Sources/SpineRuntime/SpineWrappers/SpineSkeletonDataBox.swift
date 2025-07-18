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
        static func dispose(_ pointer: spine_skeleton_data) {
            spine_skeleton_data_dispose(pointer)
            //            spine_cpp_lite.spine_skeleton_data_dispose(pointer)
        }

    }

    @usableFromInline
    typealias Box = PointeeBox<spine_skeleton_data_wrapper, Cleanup>

    @nonobjc
    internal let pAtlas: SpineAtlasBox
    @nonobjc
    internal let box: Box

    @nonobjc
    private var nativePointer: spine_skeleton_data {
        self.box._pointer
    }

    // expects skeletonData is created from the given atlas
    @nonobjc
    public init(
        atlas: SpineAtlasBox,
        skeletonData: spine_skeleton_data
    ) {
        self.pAtlas = atlas
        self.box = .init(skeletonData)
        super.init()
    }

    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skeletonData:)
    public convenience init(
        invalidForSwift atlas: SpineAtlasBox,
        invalidForSwift skeletonData: spine_skeleton_data
    ) {
        self.init(atlas: atlas, skeletonData: .init(skeletonData))
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:json:scale:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        json: String,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, json: json, scale: scale)
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:jsonPath:scale:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        jsonPath: String,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, jsonPath: jsonPath, scale: scale)
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:binary:scale:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        binary: Data,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, binary: binary, scale: scale)
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skelPath:scale:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        skelPath: String,
        scale: Float = 1
    ) throws {
        try self.init(atlas: atlas, skelPath: skelPath, scale: scale)
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:json:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        json: String
    ) throws {
        try self.init(atlas: atlas, json: json)
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:jsonPath:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        jsonPath: String
    ) throws {
        try self.init(atlas: atlas, jsonPath: jsonPath)
    }
    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:binary:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        binary: Data
    ) throws {
        try self.init(atlas: atlas, binary: binary)

    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:skelPath:error:)
    public convenience init(
        notForSwift atlas: SpineAtlasBox,
        skelPath: String
    ) throws {
        try self.init(atlas: atlas, skelPath: skelPath)
    }

    @objc
    open var atlas: SpineAtlasBox { pAtlas }

    @available(swift, obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (spine_skeleton_data) -> Void
    ) {
        withUnsafeMutablePointer(to: &self[]) {
            body($0)
        }
    }

    @nonobjc
    @inline(__always)
    public subscript() -> spine_skeleton_data_wrapper {
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
        atlas: SpineAtlasBox,
        json: String,
        scale: Float = 1
    ) throws(SpineParsingError) {
        let reader = spine_skeleton_json_create(&atlas[])
        defer {
            spine_skeleton_json_dispose(reader)
        }
        spine_skeleton_json_set_scale(reader, scale)
        //        reader.setScale(scale)
        let dataBlock = spine_skeleton_json_read_skeleton_data(reader, json)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: UnsafeMutableRawPointer(dataBlock).assumingMemoryBound(to: spine_skeleton_data_wrapper.self))
        } else {
            let error = spine_skeleton_json_get_error(reader)
            let message = if let error { String(cString: error) } else { "" }
            throw SpineParsingError(message)
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas: SpineAtlasBox,
        jsonPath: String,
        scale: Float = 1
    ) throws(SpineParsingError) {
        let reader = spine_skeleton_json_create(&atlas[])
        defer {
            spine_skeleton_json_dispose(reader)
        }
        spine_skeleton_json_set_scale(reader, scale)
        //        reader.setScale(scale)
        let dataBlock = spine_skeleton_json_read_skeleton_data_file(reader, jsonPath)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: UnsafeMutableRawPointer(dataBlock).assumingMemoryBound(to: spine_skeleton_data_wrapper.self))
        } else {
            let error = spine_skeleton_json_get_error(reader)
            let message = if let error { String(cString: error) } else { "" }
            throw SpineParsingError(message)
        }
    }
    // typed Throw is unavailbe for objc interface using library evolution mode

    @nonobjc public convenience init(
        atlas: SpineAtlasBox,
        binary: Data,
        scale: Float = 1
    ) throws(SpineParsingError) {
        let reader = spine_skeleton_binary_create(&atlas[])
        defer {
            spine_skeleton_binary_dispose(reader)
        }
        spine_skeleton_binary_set_scale(reader, scale)
        //        reader.setScale(scale)
        let dataBlock = binary.withUnsafeBytes {
            spine_skeleton_binary_read_skeleton_data(reader, $0.baseAddress, Int32($0.count))
        }
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: UnsafeMutableRawPointer(dataBlock).assumingMemoryBound(to: spine_skeleton_data_wrapper.self))
        } else {
            let error = spine_skeleton_binary_get_error(reader)
            let message = if let error { String(cString: error) } else { "" }
            throw SpineParsingError(message)
        }
    }

    // typed Throw is unavailbe for objc interface using library evolution mode
    @nonobjc public convenience init(
        atlas: SpineAtlasBox,
        skelPath: String,
        scale: Float = 1
    ) throws(SpineParsingError) {
        let reader = spine_skeleton_binary_create(&atlas[])
        defer {
            spine_skeleton_binary_dispose(reader)
        }
        spine_skeleton_binary_set_scale(reader, scale)
        //        reader.setScale(scale)
        let dataBlock = spine_skeleton_binary_read_skeleton_data_file(reader, skelPath)
        if let dataBlock {
            self.init(atlas: atlas, skeletonData: UnsafeMutableRawPointer(dataBlock).assumingMemoryBound(to: spine_skeleton_data_wrapper.self))
        } else {
            let error = spine_skeleton_binary_get_error(reader)
            let message = if let error { String(cString: error) } else { "" }
            throw SpineParsingError(message)
        }
    }

}
