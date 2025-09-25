//
//  spine_apple_extension.hpp
//  spine-ios
//
//  Created by 박병관 on 7/17/25.
//

#ifndef spine_apple_extension_hpp
#define spine_apple_extension_hpp
#include <spine-c/prefix.h>
#include <spine-c/texture_loader.h>

#if __cplusplus
#include <spine/Extension.h>
#include <CoreFoundation/CoreFoundation.h>
#include <spine/TextureLoader.h>

namespace spine {
class AtlasPage;
class String;

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
    

class NSDictionaryTextureLoader: public spine::TextureLoader {
        
public:
    void load(spine::AtlasPage &page, const spine::String &path) override;
    
    void unload(void * texture) override;
        
};

    SpineExtension *getDefaultExtension();
    


    
}

#endif

SPINE_C_API spine_texture_loader spine_get_default_dictionary_texture_loader(void);

#endif /* spine_apple_extension_hpp */
