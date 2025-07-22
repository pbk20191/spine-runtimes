//
//  block_support.hpp
//  spine-ios
//
//  Created by 박병관 on 7/22/25.
//

#ifndef spine_block_support_hpp
#define spine_block_support_hpp



#if __BLOCKS__

#include "spine-cpp-lite.h"

typedef void (^SpineAnimationCallbackBlock)(spine_animation_state _Nonnull state, spine_event_type type, spine_track_entry _Nonnull entry, spine_event _Nullable event);

SPINE_CPP_LITE_EXPORT void spine_track_entry_set_block(spine_track_entry _Nonnull entry, SpineAnimationCallbackBlock _Nullable block);

SPINE_CPP_LITE_EXPORT void spine_animation_state_set_block(spine_animation_state _Nonnull state, SpineAnimationCallbackBlock _Nullable block);

#endif

#endif /* block_support_hpp */
