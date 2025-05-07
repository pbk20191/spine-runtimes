//
//  ScratchBufferSwiftProxy.swift
//  spine-ios
//
//  Created by 박병관 on 5/7/25.
//

#if canImport(Metal)
import Metal

final class ScratchBufferSwiftProxy {
    
    @nonobjc
    let buffer:(any MTLBuffer)
    @nonobjc
    let semaphore:DispatchSemaphore
    
    typealias MethodLookup = @convention(c) (AnyObject, Selector, Selector) -> (Unmanaged<NSObject>?)
    
#if DEBUG
    @nonobjc
    let methodTable:MethodLookup?
#endif
    @nonobjc static var methodSelector: Selector {
       Selector( "methodSignatureForSelector:")
    }
   
    @nonobjc
    init(buffer: any MTLBuffer, semaphore: DispatchSemaphore) {
        self.buffer = buffer
        self.semaphore = semaphore
#if DEBUG
        let type = type(of: buffer)
        if let method = class_getInstanceMethod(type, Self.methodSelector) {
            let imp = method_getImplementation(method)
            self.methodTable = unsafeBitCast(imp, to: MethodLookup.self)
        } else {
            self.methodTable = nil
        }
#endif
    }
    
    deinit {
        buffer.setPurgeableState(.empty)
        semaphore.signal()
    }
    
    @objc(forwardingTargetForSelector:)
    func forwardingTarget(for aSelector: Selector!) -> Any? {
        guard buffer.responds(to: aSelector) else { return nil }
#if DEBUG
        var description = protocol_getMethodDescription(MTLBuffer.self, aSelector, true, true)
        if description.name == aSelector {
            return nil
        }
        description = protocol_getMethodDescription(MTLBuffer.self, aSelector, false, true)
        if description.name == aSelector {
            return nil
        }
#endif
        return buffer
    }
    
    @objc(conformsToProtocol:)
    func conforms(to aProtocol: Protocol) -> Bool {
        return buffer.conforms(to: aProtocol)
    }
    
    @objc(respondsToSelector:)
    func responds(to aSelector: Selector) -> Bool {
        return buffer.responds(to: aSelector)
    }
    
    
    @available(swift, obsoleted: 1.0)
    @objc(forwardInvocation:)
    func forwardInvocation(_ invocation: NSInvocation) {
        invocation.invoke(withTarget: buffer)
    }
    
#if DEBUG
    @available(swift, obsoleted: 1.0)
    @objc(methodSignatureForSelector:)
    func methodSignature(for selector: Selector) -> NSMethodSignature! {
        guard let methodTable else { return nil }
        let object = methodTable(self.buffer, Self.methodSelector, selector)?.takeUnretainedValue()
        let signature = object as? NSMethodSignature
        return signature
    }
#endif
    
    @objc(isProxy)
    func isProxy() -> Bool {
        return true
    }
    
    @objc(isEqual:)
    func isEqual(_ object: Any?) -> Bool {
        return buffer.isEqual(object)
    }
    
    @objc(hash)
    var hash:Int {
        buffer.hash
    }
    
    @objc(isKindOfClass:)
    func isKind(of aClass: AnyClass) -> Bool {
        return buffer.isKind(of: aClass)
    }
    
    @objc(isMemberOfClass:)
    func isMember(of aClass: AnyClass) -> Bool {
        return buffer.isMember(of: aClass)
    }
    
    @objc(self)
    func `self`() -> (any MTLBuffer) {
        buffer.`self`()
    }
    
    @objc
    func contents() -> UnsafeMutableRawPointer {
        buffer.contents()
    }
    
    @objc
    var length: Int {
        buffer.length
    }
    
    @objc
    var storageMode: MTLStorageMode {
        buffer.storageMode
    }
}
#endif
