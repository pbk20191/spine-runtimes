//
//  extension.m
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

#include <spine/extension.h>
#include <CoreFoundation/CoreFoundation.h>
#include <os/signpost.h>

CF_INLINE void spin_c_extension_cf_setup() __attribute__((constructor(200)));

CF_INLINE float cf_sp_randomFloat();
CF_INLINE void* cf_malloc(size_t size);
CF_INLINE void* cf_realloc(void* ptr, size_t size);
CF_INLINE void cf_free(void* ptr);
CF_INLINE void* cf_debug_malloc(size_t size, const char* file, int line);


CF_INLINE void spin_c_extension_cf_setup() {
    _spSetMalloc(cf_malloc);
    _spSetRealloc(cf_realloc);
    _spSetFree(cf_free);
    _spSetRandom(cf_sp_randomFloat);
    
#if DEBUG
    _spSetDebugMalloc(cf_debug_malloc);
#endif
    spBone_setYDown(1);
}


void _spAtlasPage_createTexture(spAtlasPage *self, const char *path) {
    
    spAtlas * parent = self->atlas;
    spAtlasPage* cursor = parent->pages;
    CFIndex index = 0;
    while (cursor != nil) {
        if (cursor == self) {
            break;
        }
        cursor = cursor->next;
        index++;
    }
    
    CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    self->rendererObject = dictionary;
    CFStringRef keyString = CFStringCreateWithCString(kCFAllocatorDefault, "kSPPath", kCFStringEncodingUTF8);
    CFTypeRef value = CFStringCreateWithCString(kCFAllocatorDefault, path, kCFStringEncodingUTF8);
    CFDictionarySetValue(dictionary, keyString, value);
    CFRelease(keyString);
    CFRelease(value);
    keyString = CFStringCreateWithCString(kCFAllocatorDefault, "kSPName", kCFStringEncodingUTF8);
    value = CFStringCreateWithCString(kCFAllocatorDefault, self->name, kCFStringEncodingUTF8);
    CFDictionarySetValue(dictionary, keyString, value);
    CFRelease(keyString);
    CFRelease(value);
    keyString = CFStringCreateWithCString(kCFAllocatorDefault, "kSPIndex", kCFStringEncodingUTF8);
    value = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &index);
    CFDictionarySetValue(dictionary, keyString, value);
    CFRelease(keyString);
    CFRelease(value);
}

void _spAtlasPage_disposeTexture(spAtlasPage *self) {
    CFMutableDictionaryRef dictionary = self->rendererObject;
    self->rendererObject = NULL;
    CFRelease(dictionary);
}


char* _spUtil_readFile(const char *path, int *length) {
    *length = 0;
    CFURLRef url = NULL;
    {
        CFStringRef pathString = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, path, kCFStringEncodingUTF8, kCFAllocatorNull);
        CFURLPathStyle style = kCFURLPOSIXPathStyle;
        
        #if TARGET_OS_WINDOWS
        style = kCFURLWindowsPathStyle;
        #endif
        url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, pathString, kCFURLPOSIXPathStyle, false);
        CFRelease(pathString);
    }
    if (!url) {
        os_log_error(OS_LOG_DEFAULT, "Failed to create URL from %s", path);
        return NULL;
    }
    CFErrorRef cfError = NULL;
    CFNumberRef fileSize = NULL;
    {
        CFDictionaryRef dictionary = NULL;
        CFArrayRef keyArray = CFArrayCreate(kCFAllocatorDefault, (CFTypeRef[]){ kCFURLFileSizeKey, kCFURLFileAllocatedSizeKey, kCFURLTotalFileSizeKey}, 3, &kCFTypeArrayCallBacks);
        dictionary = CFURLCopyResourcePropertiesForKeys(url, keyArray, &cfError);
        CFRelease(keyArray);
        if (dictionary) {
            fileSize = CFRetain(CFDictionaryGetValue(dictionary, kCFURLFileSizeKey));
            CFRelease(dictionary);
            dictionary = NULL;
        }
    }
    if (cfError) {
        CFStringRef errorDescription = CFErrorCopyDescription(cfError);
        CFIndex errorCode = CFErrorGetCode(cfError);
        os_log_error(OS_LOG_DEFAULT, "Error reading file size: %@  errorCode: %ld", errorDescription, (long)errorCode);
        CFRelease(cfError);
        CFRelease(errorDescription);
        return NULL;
    }
    if (!fileSize) {
        os_log_error(OS_LOG_DEFAULT, "Error reading file size with unknown error");
        return NULL;
    }
    CFNumberGetValue(fileSize, kCFNumberIntType, length);
    CFRelease(fileSize);
    fileSize = NULL;
    char* block = MALLOC(char, *length);
    CFReadStreamRef stream = CFReadStreamCreateWithFile(kCFAllocatorDefault, url);
    CFRelease(url);
    url = NULL;
    CFReadStreamOpen(stream);
    const CFIndex readCount = CFReadStreamRead(stream, (UInt8*) block, *length);
    cfError = CFReadStreamCopyError(stream);
    CFReadStreamClose(stream);
    CFRelease(stream);
    if (cfError) {
        CFStringRef errorDescription = CFErrorCopyDescription(cfError);
        CFIndex errorCode = CFErrorGetCode(cfError);
        os_log_error(OS_LOG_DEFAULT, "Error reading file : %@  errorCode: %ld", errorDescription, (long)errorCode);
        CFRelease(errorDescription);
        
        
        FREE(block);
        CFRelease(cfError);
        *length = 0;
        return NULL;
    }
    assert(readCount == 0 || readCount == *length);
    return block;
}


CF_INLINE float cf_sp_randomFloat() {
    return (float)arc4random() / (float)UINT32_MAX;
}

CF_INLINE void* cf_malloc(size_t size) {
    return CFAllocatorAllocate(kCFAllocatorDefault, size, 0);
}

CF_INLINE void* cf_realloc(void* ptr, size_t size) {
    return CFAllocatorReallocate(kCFAllocatorDefault, ptr, size, 0);
}

CF_INLINE void cf_free(void* ptr) {
    CFAllocatorDeallocate(kCFAllocatorDefault, ptr);
}

CF_INLINE void* cf_debug_malloc(size_t size, const char* file, int line) {
    os_signpost_event_emit(OS_LOG_DEFAULT, 1, "_spMalloc", "file=%s line=%d size=%zu", file, line, size);
    return cf_malloc(size);
}
