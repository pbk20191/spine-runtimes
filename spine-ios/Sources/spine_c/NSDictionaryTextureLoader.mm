//
//  objc_extension.m
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//

#import <Foundation/Foundation.h>
#include <spine/AnimationState.h>
#include <spine/spine.h>
#include <spine/Skeleton.h>
//AnimationStateListenerObject
#include "NSDictionaryTextureLoader.hpp"


namespace spine_support{


void NSDictionaryTextureLoader::load(spine::AtlasPage &page, const spine::String &path) {
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

void NSDictionaryTextureLoader::unload(void *texture) {
    CFMutableDictionaryRef* cfValue = (CFMutableDictionaryRef*) texture;
    CFRelease(cfValue);
}



    static const NSDictionaryTextureLoader dictionaryLoader;
spine::TextureLoader* NSDictionaryTextureLoader::defaultLoader() {
    return const_cast<NSDictionaryTextureLoader*>(&dictionaryLoader);
}

};
