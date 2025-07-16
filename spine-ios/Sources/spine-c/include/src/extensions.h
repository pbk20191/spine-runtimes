//
//  extension.h
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#ifndef extension_h
#define extension_h
#include "src/generated/types.h"
#include "src/base.h"


#if __BLOCKS__


typedef void (^SpineAnimationCallbackBlock)(spine_animation_state _Nonnull state, spine_event_type type, spine_track_entry _Nonnull entry, spine_event _Nullable event);

SPINE_C_API void spine_track_entry_set_block(spine_track_entry _Nonnull entry, SpineAnimationCallbackBlock _Nullable block);

SPINE_C_API void spine_animation_state_set_block(spine_animation_state _Nonnull state, SpineAnimationCallbackBlock _Nullable block);

#endif

SPINE_C_API int32_t spine_major_version(void);
SPINE_C_API int32_t spine_minor_version(void);

SPINE_C_API __attribute__((weak)) void spine_enable_debug_extension(bool enable);
SPINE_C_API __attribute__((weak)) void spine_report_leaks(void);

#endif /* extension_h */
