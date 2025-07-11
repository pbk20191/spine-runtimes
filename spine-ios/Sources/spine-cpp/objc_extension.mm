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
#include "spine_public.hpp"

#ifdef __BLOCKS__
namespace spine_support{

void BlockAnimationStateListenerObject::callback(spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event) {
    if (this->block_) {
        @autoreleasepool {
            this->block_(state, type, entry, event);
        }
        
    }
}

BlockAnimationStateListenerObject::BlockAnimationStateListenerObject(AnimationCallbackBlock callback): block_(callback) {
    
}

BlockAnimationStateListenerObject::BlockAnimationStateListenerObject(): block_(nil) {
    
}

void BlockAnimationStateListenerObject::applyTo(spine::AnimationState &state) {
    state.setListener(this);
}

void BlockAnimationStateListenerObject::applyTo(spine::TrackEntry &entry) {
    entry.setListener(this);
}

void applyListenerTo(spine::AnimationState &state, AnimationCallbackBlock cb) {
    if (!cb) {
        return;
    }
    state.setListener([cb](spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event){
        cb(state, type, entry, event);
    });
}

void applyListenerTo(spine::TrackEntry &entry, AnimationCallbackBlock cb) {
    if (!cb) {
        return;
    }
    entry.setListener([cb](spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event){
        cb(state, type, entry, event);
    });
}

void NSDictionaryTextureLoader::load(spine::AtlasPage &page, const spine::String &path) {
#define page_v(key) @#key : @(page.key),
#define page_s(key) @#key : page.key.isEmpty() ? @"" : [NSString stringWithUTF8String:page.key.buffer()],
    @autoreleasepool {
        
        NSMutableDictionary<NSString*, id>* dict = NSMutableDictionary.dictionary;
        dict[@"kSpineAtlasPageProperty"] = @{
            page_s(name)
            page_s(texturePath)
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
        dict[@"kSpineTexturePath"] = [NSString stringWithUTF8String:path.buffer()];
        dict[@"kSpineAtlasPagePointer"] = [NSValue valueWithPointer:&page];
        page.texture = (__bridge_retained CFMutableDictionaryRef)dict;
    }
}

void NSDictionaryTextureLoader::unload(void *texture) {
    CFMutableDictionaryRef* cfValue = (CFMutableDictionaryRef*) texture;
    CFRelease(cfValue);
}

spine::RenderCommand* spine_render(spine::SkeletonRenderer &renderer, spine::Skeleton &skeleton) {
    float x;
    float y;
    float width;
    float height;
    spine::Vector<float> vertices;
    spine::SkeletonClipping clipper;
    //    void getBounds(float &outX, float &outY, float &outWidth, float &outHeight, Vector<float> &outVertexBuffer);
    //    void getBounds(float &outX, float &outY, float &outWidth, float &outHeight, Vector<float> &outVertexBuffer, SkeletonClipping *clipper);
    
    skeleton.getBounds(x, y, width, height, vertices, &clipper);
    return renderer.render(skeleton);
}



    static const NSDictionaryTextureLoader dictionaryLoader;
spine::TextureLoader* NSDictionaryTextureLoader::defaultLoader() {
    return const_cast<NSDictionaryTextureLoader*>(&dictionaryLoader);
}

};

#endif

