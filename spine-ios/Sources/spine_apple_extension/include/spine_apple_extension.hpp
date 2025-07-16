//
//  spine_apple_extension.hpp
//  spine-ios
//
//  Created by 박병관 on 7/17/25.
//

#ifndef spine_apple_extension_hpp
#define spine_apple_extension_hpp

#if __cplusplus
#include <spine/Extension.h>
#include <CoreFoundation/CoreFoundation.h>

namespace spine {


class AppleExtension: public spine::SpineExtension {

public:
    const CFAllocatorRef allocator;
    
    AppleExtension();
    AppleExtension(const CFAllocatorRef);
    
    void * _alloc(size_t size, const char *file, int line) override;
    
    void * _realloc(void *ptr, size_t size, const char *file, int line) override;
    
    void * _calloc(size_t size, const char *file, int line) override;
    
    void _free(void *mem, const char *file, int line) override;
    
    char* _readFile(const spine::String &path, int *length) override;
    
};

    SpineExtension *getDefaultExtension();
}

#endif
#endif /* spine_apple_extension_hpp */
