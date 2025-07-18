//
//  PointeeBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/5/25.
//

@usableFromInline
internal protocol BoxDisposerProtocol<Pointee>: Sendable, Copyable {

    associatedtype Pointee

    static func dispose(_ pointer: UnsafeMutablePointer<Pointee>)

}

@usableFromInline
internal struct PointeeBox<T: Copyable, C: BoxDisposerProtocol>: ~Copyable where C.Pointee == T {


    @usableFromInline
    internal let _pointer: UnsafeMutablePointer<T>


    @usableFromInline
    internal init(_ pointee: UnsafeMutablePointer<T>) {
        self._pointer = pointee
    }

    deinit {
        C.dispose(_pointer)
    }

    @inline(__always)
    @inlinable
    public subscript() -> T {
        @inline(__always)
        @_transparent
        @inlinable
        borrowing unsafeAddress {
            UnsafePointer<T>(_pointer)
        }
        //
        @inline(__always)
        @_transparent
        @inlinable
        nonmutating unsafeMutableAddress {
            _pointer
        }
    }

}
