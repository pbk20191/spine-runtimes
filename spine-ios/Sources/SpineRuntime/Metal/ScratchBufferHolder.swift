//
//  ScratchBufferHolder.swift
//  spine-ios
//
//  Created by 박병관 on 5/7/25.
//

#if canImport(Metal)
    import Metal

    final class ScratchBufferHolder: SpineVertexBuffer {

        let buffer: any MTLBuffer
        let semaphore: DispatchSemaphore

        init(buffer: any MTLBuffer, semaphore: DispatchSemaphore) {
            self.buffer = buffer
            self.semaphore = semaphore
        }

        deinit {
            buffer.setPurgeableState(.empty)
            semaphore.signal()
        }

        let offsetInBytes: Int = 0

    }
#endif
