//
//  spine_ns_dictionary_texture_loader.c
//  spine-ios
//
//  Created by 박병관 on 8/11/25.
//
#include <spine/spine.h>
#include "spine_ns_dictionary_texture_loader.h"

namespace {

class NSDictionaryTextureLoader: public spine::TextureLoader {
    
public:
    void load(spine::AtlasPage &page, const spine::String &path) override {
#define page_v(key) @#key : @(page.key),
#define page_s(key) @#key : page.key.isEmpty() ? @"" : [NSString stringWithUTF8String:page.key.buffer()],
        @autoreleasepool {
            NSMutableDictionary<NSString*, id>* dict = NSMutableDictionary.dictionary;
            dict[@"kSpineAtlasPageProperty"] = @{
                page_s(name)
                @"texturePath":  [NSString stringWithUTF8String:path.buffer()],
                page_v(format)
                page_v(minFilter)
                page_v(magFilter)
                page_v(uWrap)
                page_v(vWrap)
                page_v(width)
                page_v(height)
                page_v(pma)
                page_v(index)
            };
            dict[@"kSpineAtlasPagePointer"] = [NSValue valueWithPointer:&page];
            page.texture = (__bridge_retained CFMutableDictionaryRef)dict;
        }
    }
    
    void unload(void * _Null_unspecified texture) override {
        if (texture) {
            id value = (__bridge_transfer id) texture;
        }
    }
    
};



}


spine_texture_loader spine_get_default_dictionary_texture_loader(void) {
    static NSDictionaryTextureLoader dictionaryLoader;
    
    return reinterpret_cast<spine_texture_loader>(&dictionaryLoader);
}
