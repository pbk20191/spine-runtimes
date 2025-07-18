import Foundation
//
//  File.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//
import spine_c

extension spine_atlas_page {

    public var dictionaryTexture: NSMutableDictionary {
        Unmanaged<NSMutableDictionary>.fromOpaque(spine_atlas_page_get_texture(self)).takeUnretainedValue()
    }

}

extension ContiguousArray {


    @inline(__always)
    internal subscript<Value>(_ key: Index, safe2 block: @autoclosure () -> Value?) -> Value? where Self.Element == Value? {
        mutating get {
            if !indices.contains(key) {
                return nil
            }
            if let value = self[key] { return value }
            if let newValue = block() {
                self[key] = newValue
                return newValue
            }
            return nil
        }
    }

}

extension Dictionary {

    @inline(__always)
    internal subscript(_ key: Key, safe block: @autoclosure () -> Value) -> Value {
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
    internal subscript(_ key: Key, safe2 block: @autoclosure () -> Value?) -> Value? {
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
