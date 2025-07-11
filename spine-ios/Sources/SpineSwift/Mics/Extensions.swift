//
//  File.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//
import spine_cpp
import Foundation

extension UnsafePointer where Pointee ==  spine.AtlasPage {
    
    var dictionaryTexture:NSMutableDictionary {
        Unmanaged<NSMutableDictionary>.fromOpaque(self.pointee.texture).takeUnretainedValue()
    }
    
}

extension Dictionary {

    @inline(__always)
    internal subscript(_ key:Key, safe block : @autoclosure () -> Value) -> Value {
        mutating get {
            if let value = self[key] { return value }
            let newValue = block()
            self[key] = newValue
            return newValue
        }
    }
    
}

extension Dictionary {

    @inline(__always)
    internal subscript(_ key:Key, safe2 block : @autoclosure () -> Value?) -> Value? {
        mutating get {
            if let value = self[key] { return value }
            if let newValue = block() {
                self[key] = newValue
                return newValue
            }
            return nil
        }
    }
    
}
