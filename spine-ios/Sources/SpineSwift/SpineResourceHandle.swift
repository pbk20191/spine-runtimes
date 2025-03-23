//
//  SpineResourceHandle.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

import spine_c
import Foundation


@objcMembers
public final class SpineResourceHandle: NSObject {
    
    @nonobjc
    private override init() {
        super.init()
    }
    
    
    public static func parseAndCreateAtlas(
        atlasTxt:String,
        dirPath:String = "",
        rendererObject:UnsafeMutableRawPointer?
    ) throws(SpineParsingError) -> UnsafeMutablePointer<spAtlas> {
        
        guard
            let atlas = spAtlas_create(atlasTxt, Int32(atlasTxt.utf8CString.count), dirPath, rendererObject)
        else {
            throw SpineParsingError("atlasCreationFailed")
        }
        if atlas.pointee.pages == nil {
            spAtlas_dispose(atlas)
            throw SpineParsingError("atlasCreationFailed")
        }
        if atlas.pointee.regions == nil {
            spAtlas_dispose(atlas)
            throw SpineParsingError("atlasCreationFailed")
        }
        return atlas
        
    }
    
    public static func parseAndCreateData(
        jsonTxt:String,
        atlas:UnsafeMutablePointer<spAtlas>
    ) throws(SpineParsingError) -> UnsafeMutablePointer<spSkeletonData> {
        guard let jsonParser = spSkeletonJson_create(atlas) else {
            throw SpineParsingError("jsonParserCreationFailed")
        }
        defer {
            spSkeletonJson_dispose(jsonParser)
        }
        let skeletonData = spSkeletonJson_readSkeletonData(
            jsonParser, jsonTxt
        )
        if let errorPtr = jsonParser.pointee.error,
           let errorMsg = String(utf8String: errorPtr) {
            if skeletonData != nil {
                spSkeletonData_dispose(skeletonData)
            }
            throw SpineParsingError(errorMsg)
        }
        guard let skeletonData else {
            throw SpineParsingError("skeletonDataCreationFailed")
        }
        return skeletonData
    }
    
    public static func parseAndCreateData(
        skelBinary:Data,
        atlas:UnsafeMutablePointer<spAtlas>
    ) throws(SpineParsingError) -> UnsafeMutablePointer<spSkeletonData> {
        guard let binaryParser = spSkeletonBinary_create(atlas) else {
            throw SpineParsingError("binaryParserCreationFailed")
        }
        defer {
            spSkeletonBinary_dispose(binaryParser)
        }
        let skeletonData = spSkeletonBinary_readSkeletonData(
            binaryParser, skelBinary.withUnsafeBytes { $0.baseAddress }, Int32(skelBinary.count)
        )
        if let errorPtr = binaryParser.pointee.error,
           let errorMsg = String(utf8String: errorPtr) {
            if skeletonData != nil {
                spSkeletonData_dispose(skeletonData)
            }
            throw SpineParsingError(errorMsg)
        }
        guard let skeletonData else {
            throw SpineParsingError("skeletonDataCreationFailed")
        }
        return skeletonData
    }
    
}
