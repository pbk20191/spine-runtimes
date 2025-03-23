//
//  TextureIdentifier.swift
//  spine-ios
//
//  Created by 박병관 on 3/23/25.
//


internal struct TextureIdentifier: Hashable, Sendable {
    
    public var name:String
    public var index:Int
    public var pma:Bool
    
    public init(name: String, index: Int, pma: Bool) {
        self.name = name
        self.index = index
        self.pma = pma
    }
    
}
