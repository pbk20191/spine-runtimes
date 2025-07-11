//
//  Header.h
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//

#ifndef Header_h
#define Header_h


#include <spine/AnimationState.h>
#include <spine/SkeletonRenderer.h>
#include <functional>
#include <spine/spine.h>
#include <spine/Animation.h>
#include "spine_swift_bridge.hpp"

namespace spine_support {
#ifdef __BLOCKS__

typedef void (^AnimationCallbackBlock)(spine::AnimationState * _Nonnull state, spine::EventType type, spine::TrackEntry * _Nonnull entry, spine::Event * _Nullable event);

class BlockAnimationStateListenerObject: public spine::AnimationStateListenerObject {
public:
    BlockAnimationStateListenerObject(AnimationCallbackBlock _Null_unspecified block);
    BlockAnimationStateListenerObject();


    void callback(spine::AnimationState * _Nonnull state, spine::EventType type, spine::TrackEntry * _Nonnull entry, spine::Event * _Nullable event) override ;

    void applyTo(spine::AnimationState &state);
    
    void applyTo(spine::TrackEntry &entry);
private:
    AnimationCallbackBlock _Null_unspecified block_;
};


void applyListenerTo(spine::AnimationState &state, AnimationCallbackBlock _Nonnull cb);
void applyListenerTo(spine::TrackEntry &entry, AnimationCallbackBlock _Nonnull cb);
#endif

spine::RenderCommand * _Nullable spine_render(spine::SkeletonRenderer& renderer ,spine::Skeleton &skeleton);


class NSDictionaryTextureLoader: public spine::TextureLoader {

public:
    void load(spine::AtlasPage &page, const spine::String &path) override;
    
    void unload(void * _Null_unspecified texture) override;
    
    
    static spine::TextureLoader* _Nonnull  defaultLoader(void);
};




}




#endif /* Header_h */

/*
Vector<int> splits;
Vector<int> pads;
Vector <String> names;
Vector<float> values;
};

class TextureLoader;

class SP_API Atlas : public SpineObject {
public:
Atlas(const String &path, TextureLoader *textureLoader, bool createTexture = true);

Atlas(const char *data, int length, const char *dir, TextureLoader *textureLoader, bool createTexture = true);

~Atlas();

void flipV();

/// Returns the first region found with the specified name. This method uses String comparison to find the region, so the result
/// should be cached rather than calling this method multiple times.
/// @return The region, or NULL.
AtlasRegion *findRegion(const String &name);

Vector<AtlasPage *> &getPages();

Vector<AtlasRegion *> &getRegions();
*/
