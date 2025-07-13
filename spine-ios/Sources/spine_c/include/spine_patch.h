//
//  patch_file.hpp
//  spine-ios
//
//  Created by 박병관 on 7/12/25.
//

#ifndef patch_file_hpp
#define patch_file_hpp
#include <CoreFoundation/CoreFoundation.h>
#include "spine-cpp-lite.h"


#if __BLOCKS__

typedef void (^SpineAnimationCallbackBlock)(spine_animation_state _Nonnull state, spine_event_type type, spine_track_entry _Nonnull entry, spine_event _Nullable event);

SPINE_CPP_LITE_EXPORT void spine_track_entry_set_block(spine_track_entry _Nonnull entry, SpineAnimationCallbackBlock _Nullable block);

SPINE_CPP_LITE_EXPORT void spine_animation_state_set_block(spine_animation_state _Nonnull state, SpineAnimationCallbackBlock _Nullable block);

#endif

SPINE_CPP_LITE_EXPORT void spine_animation_state_dispose(spine_animation_state _Nullable state);
SPINE_CPP_LITE_EXPORT void spine_animation_state_data_dispose(spine_animation_state_data _Nullable state);

SPINE_CPP_LITE_EXPORT void spine_skeleton_dispose(spine_skeleton _Nullable state);

SPINE_CPP_LITE_EXPORT _Nonnull spine_animation_state_data spine_animation_state_data_create(spine_skeleton_data _Nonnull data);

SPINE_CPP_LITE_EXPORT _Nonnull spine_skeleton spine_skeleton_create(spine_skeleton_data _Nonnull data);

SPINE_CPP_LITE_EXPORT _Nonnull spine_animation_state spine_animation_state_create(spine_animation_state_data _Nonnull data);


SPINE_CPP_LITE_EXPORT  void* _Nullable  spine_render_command_get_texture(spine_render_command _Nonnull cmd);

typedef struct {
    float x,y,width,height;
} spine_skeleton_rect;

SPINE_CPP_LITE_EXPORT spine_skeleton_rect spine_skeleton_current_rect(spine_skeleton _Nonnull self, spine_bool useClipping);

#endif /* patch_file_hpp */
