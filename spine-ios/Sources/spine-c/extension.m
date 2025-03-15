//
//  extension.m
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

#import <Foundation/Foundation.h>
#import <spine/extension.h>
#import <OSLog/OSLog.h>

float randomFloat();
void* cf_malloc(size_t size);
void* cf_realloc(void* ptr, size_t size);
void cf_free(void* ptr);
void* cf_debug_malloc(size_t size, const char* file, int line);

__attribute__((constructor(200)))
void beforeMain() {
    _spSetMalloc(cf_malloc);
    _spSetRealloc(cf_realloc);
    _spSetFree(cf_free);
    _spSetRandom(randomFloat);
    
#if DEBUG
    _spSetDebugMalloc(cf_debug_malloc);
#endif
}


void _spAtlasPage_createTexture(spAtlasPage *self, const char *path) {
    NSString* pathString = [NSString stringWithUTF8String:path];
    NSMutableDictionary<NSString*, id>* dictionary = NSMutableDictionary.dictionary;
    dictionary[@"spPath"] = pathString;
    NSString* nameString = [NSString stringWithUTF8String:self->name];
    dictionary[@"spName"] = nameString;
    self->rendererObject = (__bridge_retained CFMutableDictionaryRef)(dictionary);
}

void _spAtlasPage_disposeTexture(spAtlasPage *self) {
    NSMutableDictionary* dictionary = (__bridge_transfer NSMutableDictionary*)self->rendererObject;
    self->rendererObject = NULL;
}

char* _spUtil_readFile(const char *path, int *length) {
    NSString* pathString = [NSString stringWithUTF8String:path];
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:pathString options:NSDataReadingMappedIfSafe error:&error];
    if (data == nil) {
        return NULL;
    }
    if (error) {
        os_log_error(OS_LOG_DEFAULT, "Error reading file: %@", error);
        return NULL;
    }
    *length = (int)data.length;
    char* block = MALLOC(char, data.length);
    [data getBytes:block length:data.length];
    return block;
}



float randomFloat() {
    return (float)arc4random() / (float)UINT32_MAX;
}

void* cf_malloc(size_t size) {
    return CFAllocatorAllocate(kCFAllocatorDefault, size, 0);
}

void* cf_realloc(void* ptr, size_t size) {
    return CFAllocatorReallocate(kCFAllocatorDefault, ptr, size, 0);
}

void cf_free(void* ptr) {
    CFAllocatorDeallocate(kCFAllocatorDefault, ptr);
}

void* cf_debug_malloc(size_t size, const char* file, int line) {
    os_signpost_event_emit(OS_LOG_DEFAULT, 1, "_spMalloc", "file=%s line=%d size=%zu", file, line, size);
    return cf_malloc(size);
}
