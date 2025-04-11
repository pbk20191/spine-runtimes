//
//  SpineSkeletonDataBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import Foundation
import spine_c

open class SpineSkeletonDataBox: NSObject {
        
    @nonobjc
    internal let pAtlas: SpineAtlasBox
    @nonobjc
    internal let nativePointer: UnsafeMutablePointer<spSkeletonData>
    
    // expects skeletonData is created from the given atlas
    @nonobjc
    public init(
        atlas: SpineAtlasBox,
        skeletonData: UnsafeMutablePointer<spSkeletonData>
    ) {
        self.pAtlas = atlas
        self.nativePointer = skeletonData
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
    
    @objc public convenience init(
        atlas:SpineAtlasBox,
        json:String
    ) throws(SpineParsingError) {
        let reader = spSkeletonJson_create(atlas.nativePointer)!
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
    
    @objc public convenience init(
        atlas:SpineAtlasBox,
        jsonPath:String
    ) throws(SpineParsingError) {
        let reader = spSkeletonJson_create(atlas.nativePointer)!
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
    
    @objc public convenience init(
        atlas:SpineAtlasBox,
        binary:Data
    ) throws(SpineParsingError) {
        let reader = spSkeletonBinary_create(atlas.nativePointer)!
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
    
    @objc public convenience init(
        atlas:SpineAtlasBox,
        skelPath:String
    ) throws(SpineParsingError) {
        let reader = spSkeletonBinary_create(atlas.nativePointer)!
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
    
    deinit {
        spSkeletonData_dispose(nativePointer)
    }
    
    @objc
    open var atlas: SpineAtlasBox { pAtlas }
        
    @available(swift ,obsoleted: 1.0)
    @objc
    public func accessSkeleton(
        _ body: (UnsafeMutablePointer<spSkeletonData>) -> Void
    ) {
        body(nativePointer)
    }
    
    @nonobjc
    public subscript() -> spSkeletonData {
        unsafeAddress {
            UnsafePointer(nativePointer)
        }
        unsafeMutableAddress { nativePointer }
    }
    
}
