//
//  block_support.cpp
//  spine-ios
//
//  Created by 박병관 on 7/22/25.
//

#include "spine-c/extensions/block_support.h"
#import <Foundation/Foundation.h>
#include <spine/spine.h>

template <typename Base>
struct BlockSelector;

template <>
struct BlockSelector<spine::TrackEntry> {
    static SpineAnimationCallbackBlock select(spine::AnimationState*, spine::TrackEntry* entry) {
        return (__bridge SpineAnimationCallbackBlock)entry->getRendererObject();
    }
};

template <>
struct BlockSelector<spine::AnimationState> {
    static SpineAnimationCallbackBlock select(spine::AnimationState* state, spine::TrackEntry*) {
        return (__bridge SpineAnimationCallbackBlock)state->getRendererObject();
    }
};

template <typename Base>
static inline void dispatch_block_callback(spine::AnimationState* state,
                                           spine::EventType type,
                                           spine::TrackEntry* entry,
                                           spine::Event* event) {
    SpineAnimationCallbackBlock block = BlockSelector<Base>::select(state, entry);
    if (!block) return;
    block(
        reinterpret_cast<spine_animation_state>(state),
        static_cast<spine_event_type>(type),
        reinterpret_cast<spine_track_entry>(entry),
        reinterpret_cast<spine_event>(event)
    );
}

static inline void release_cb(void* info) {
    if (info) {
        auto block = (__bridge_transfer SpineAnimationCallbackBlock)info;
        SP_UNUSED(block);
    }
}

template<typename Base>
static inline void spine_set_block(Base* self, SpineAnimationCallbackBlock block) {
    if (!self) {
        return;
    }
    if (!block) {
        spine::AnimationStateListenerObject* dummy = nullptr;
        self->setListener(dummy);
#if !SPINE_USE_STD_FUNCTION
        self->setRendererObject(0);
#endif
    } else {
#if SPINE_USE_STD_FUNCTION
        self->setListener([block](spine::AnimationState* state, spine::EventType type, spine::TrackEntry* entry, spine::Event* event){
            @autoreleasepool {
                block(
                      reinterpret_cast<spine_animation_state>(state),
                      static_cast<spine_event_type>(type),
                      reinterpret_cast<spine_track_entry>(entry),
                      reinterpret_cast<spine_event>(event)
                      );
            }
        });
#else
        self->setRendererObject((__bridge_retained void*) block, release_cb);
        self->setListener(dispatch_block_callback<Base>);
#endif
    }
}

void spine_animation_state_set_block(spine_animation_state state, SpineAnimationCallbackBlock block) {
    if (!state) {
        return;
    }
    spine::AnimationState* self = reinterpret_cast<spine::AnimationState*>(state);
    spine_set_block(self, block);
}

void spine_track_entry_set_block(spine_track_entry entry, SpineAnimationCallbackBlock block) {
    if (!entry) {
        return;
    }
    spine::TrackEntry* self = reinterpret_cast<spine::TrackEntry*>(entry);
    spine_set_block(self, block);

}
