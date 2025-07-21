//
//  spine_apple_extension.cpp
//  spine-ios
//
//  Created by 박병관 on 7/17/25.
//

#include "spine_apple_extension.hpp"
#include <spine/spine.h>
#include <Foundation/Foundation.h>
#include <OSLog/OSLog.h>
#include <os/signpost.h>
#include <dispatch/dispatch.h>
#define LOG_CATEGORY "com.esotericsoftware.spine"

namespace spine {


AppleExtension::AppleExtension(): spine::SpineExtension(), allocator(kCFAllocatorDefault) {
    
}
AppleExtension::AppleExtension(const CFAllocatorRef allocator): allocator(allocator), spine::SpineExtension() {
    
}

void * AppleExtension::_alloc(size_t size, const char *file, int line)  {
    SP_UNUSED(file);
    SP_UNUSED(line);
    return CFAllocatorAllocate(allocator, size, 0);
}

void * AppleExtension::_realloc(void *ptr, size_t size, const char *file, int line)  {
    SP_UNUSED(file);
    SP_UNUSED(line);
    return CFAllocatorReallocate(allocator, ptr, size, 0);
}

void * AppleExtension::_calloc(size_t size, const char *file, int line) {
    void* ptr = _alloc(size, file, line);
    memset(ptr, 0, size);
    return ptr;
}

void AppleExtension::_free(void *mem, const char *file, int line) {
    SP_UNUSED(file);
    SP_UNUSED(line);
    CFAllocatorDeallocate(allocator, mem);
}

char* AppleExtension::_readFile(const spine::String &path, int *length) {
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

}


spine::SpineExtension* spine::getDefaultExtension() {    
    static AppleExtension extension;
    return &extension;
}

namespace {

class DictionaryTextureLoader: public spine::TextureLoader {
    
    
    public:
    DictionaryTextureLoader(): spine::TextureLoader() {}

    void load(spine::AtlasPage &page, const spine::String &path) override {
        #define P_VALUE(key) @#key : @(page.key),
        NSMutableDictionary* buffer = NSMutableDictionary.dictionary;
        page.texture = (__bridge_retained CFMutableDictionaryRef)buffer;
        buffer[@"kSpineTextureProperty"] = @{
            @"textuerPath": [NSString stringWithUTF8String:path.buffer()],
            @"name": [NSString stringWithUTF8String:page.name.buffer()],
            P_VALUE(width)
            P_VALUE(height)
            P_VALUE(index)
            P_VALUE(pma)
            P_VALUE(uWrap)
            P_VALUE(vWrap)
            P_VALUE(magFilter)
            P_VALUE(minFilter)
            P_VALUE(format)
        };
        buffer[@"kSpineTextureNativePointer"] = [NSValue valueWithPointer:&page];
    }
    
    void unload(void *texture) override {
        id ref = (__bridge_transfer id)texture;
        SP_UNUSED(ref);
    }
    
};


}
