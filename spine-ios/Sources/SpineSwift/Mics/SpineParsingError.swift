//
//  SpineParsingError.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

public struct SpineParsingError: Error, Hashable, Sendable {
    
    internal let message: String
    
    internal init(_ message: String) {
        self.message = message
    }
    
    public var localizedDescription: String { message }
    
}
