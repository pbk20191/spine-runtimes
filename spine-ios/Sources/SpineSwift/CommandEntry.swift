//
//  CommandEntry.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
import spine_c
import SpineShadersStructs
import Foundation

internal struct CommandEntry:  Sendable {
    
    public typealias VertexBuffer =  ContiguousArray<SpineAdvancedVertex>

    
    public var verteArray:VertexBuffer

    public var metaInfo:Array<CommandMeta>

//    let sizeInfo:SizeInfo
    
    internal struct CommandMeta: Hashable, Sendable {
        
        public let textureId:TextureIdentifier
        public let blendMode:spBlendMode
        public let slice:VertexBuffer.Indices
        
        public init(textureId: TextureIdentifier, blendMode: spBlendMode, slice: VertexBuffer.Indices) {
            self.textureId = textureId
            self.blendMode = blendMode
            self.slice = slice
        }
        
    }
    
    public init() {
        self.verteArray = []
        self.metaInfo = []
    }

}


internal final class CommandEntryContext: NSObject, Sendable, NSFastEnumeration {
    
    
    public func countByEnumerating(with state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int {
        let startIndex = Int(bitPattern: state.pointee.state)
        var count = 0
        state.pointee.itemsPtr = buffer
        for i in startIndex..<entry.metaInfo.endIndex {
            if count == len {
                break
            }
            buffer.advanced(by: count).pointee = CommandEntryMetaData(imp: imp.metaInfo[i])
            count += 1
        }
        state.pointee.state += .init(bitPattern: count)
        return count
    }
    
    
    internal let imp:CommandEntry
    

    public var entry:CommandEntry { imp }
    
    init(imp: CommandEntry) {
        self.imp = imp
    }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public var metaDataCount: Int { imp.metaInfo.count }
    
    @available(swift ,obsoleted: 1.0)
    @objc
    public final func accessVertex(
        _ body: (UnsafePointer<SpineAdvancedVertex>?, Int) -> Void
    ) {
        imp.verteArray.withUnsafeBufferPointer {
            body($0.baseAddress, $0.count)
        }
    }
    
    
    @available(swift ,obsoleted: 1.0)
    @objc public subscript (index: Int) -> CommandEntryMetaData {
        get {
            .init(imp: imp.metaInfo[index])
        }
    }
    
}

internal final class CommandEntryMetaData:NSObject {
    
    private let imp:CommandEntry.CommandMeta
    
    internal init(imp: CommandEntry.CommandMeta) {
        self.imp = imp
    }
    
    @objc
    public var slice:NSRange {
        NSRange(location: imp.slice.lowerBound, length: imp.slice.count)
    }
    
    @objc
    public var blendMode:spBlendMode { imp.blendMode }
    
    @objc
    public var pageName:String { imp.textureId.name }
    
    @objc
    public var pageIndex:Int { imp.textureId.index }
    
    @objc
    public var pma:Bool { imp.textureId.pma }
    
}
