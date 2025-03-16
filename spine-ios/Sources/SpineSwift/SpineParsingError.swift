//
//  SpineParsingError.swift
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

public struct SpineParsingError: Error, Hashable, Sendable {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
    
}
