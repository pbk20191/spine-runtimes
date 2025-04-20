//
//  PointeeBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/5/25.
//


internal struct PointeeBox<T:Copyable>:~Copyable {
    
    
    @usableFromInline
    internal let _pointer:UnsafeMutablePointer<T>
    
    
    @usableFromInline
    internal init(_ pointee:UnsafeMutablePointer<T>) {
        self._pointer = pointee
    }
    
    
    public subscript() ->T {
      @_transparent
      unsafeAddress {
        UnsafePointer<T>(_pointer)
      }

      @_transparent
      nonmutating unsafeMutableAddress {
        _pointer
      }
    }
    
}
