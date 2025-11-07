//
//  block_support.hpp
//  spine-ios
//
//  Created by 박병관 on 7/22/25.
//

#ifndef spine_block_support_hpp
#define spine_block_support_hpp

#include <spine-c.h>

#if __BLOCKS__



typedef void (^SpineAnimationCallbackBlock)(spine_animation_state _Nonnull state, spine_event_type type, spine_track_entry _Nonnull entry,
											spine_event _Nullable event);

SPINE_C_API void spine_track_entry_set_block(spine_track_entry _Nonnull entry, SpineAnimationCallbackBlock _Nullable block);

SPINE_C_API void spine_animation_state_set_block(spine_animation_state _Nonnull state, SpineAnimationCallbackBlock _Nullable block);

#endif


#endif /* spine_block_support_hpp */
