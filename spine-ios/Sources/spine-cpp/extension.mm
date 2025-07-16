//
//  extension.cpp
//  spine-ios
//
//  Created by 박병관 on 7/10/25.
//

#include <spine/Extension.h>
#include <Foundation/Foundation.h>
#include <cstring>
#include <os/signpost.h>
#include <spine/SpineString.h>
#include <dispatch/dispatch.h>
#include <spine/Debug.h>
#define LOG_CATEGORY "com.esotericsoftware.spine"
#include <malloc/malloc.h>
#include <dispatch/dispatch.h>

namespace spine_support {


class AppleExtension: public spine::DefaultSpineExtension {
    

    static inline CFAllocatorRef allocator(void) {

        return (CFAllocatorRef) kCFAllocatorDefault;
    }
    
public:
    AppleExtension():spine::DefaultSpineExtension() {}
    
    void * _alloc(size_t size, const char *file, int line) override {
        
        return CFAllocatorAllocate(allocator(), size, 0);
        
    }
    
    void * _realloc(void *ptr, size_t size, const char *file, int line) override {
        return CFAllocatorReallocate(allocator(), ptr, size, 0);
    }
    
    void * _calloc(size_t size, const char *file, int line) override {
        void* ptr = _alloc(size, file, line);
        std::memset(ptr, 0, size);
        return ptr;
    }
    
    void _free(void *mem, const char *file, int line) override {
        CFAllocatorDeallocate(allocator(), mem);
    }
    
    char* _readFile(const spine::String &path, int *length) override {
        char* block = nil;
        *length = 0;
        @autoreleasepool {
            os_log_t logger = os_log_create(LOG_CATEGORY, "file");
            NSURL* url = [NSURL fileURLWithFileSystemRepresentation:path.buffer() isDirectory:false relativeToURL:nil];
            
            if (!url) {
                os_log_error(logger, "Failed to create NSURL from path: %s", path.buffer());
                *length = 0;
                block = nil;
            }
            if (url) {
                NSError* error = nil;
                NSData* data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
                if (error) {
                    os_log_error(logger, "Error reading file size: %@ errorCode: %ld", error, error.code);
                } else if (data == nil) {
                    os_log_error(logger, "Error reading file with unknown error from %@", url);
                }
                if (error || data == nil) {
                    *length = 0;
                    block = nil;
                }
                *length = (int) data.length;
                block = alloc<char>(data.length, __FILE__, __LINE__);
                
                memcpy(block, data.bytes, data.length);
            }

        }
        return block;
    }
    
};

static AppleExtension extension;


}

spine::SpineExtension* spine::getDefaultExtension() {
    return &spine_support::extension;
}
