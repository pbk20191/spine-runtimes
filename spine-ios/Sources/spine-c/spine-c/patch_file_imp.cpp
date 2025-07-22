//
//  patch_file.cpp
//  spine-ios
//
//  Created by 박병관 on 7/12/25.
//
#include <spine-c/spine_patch.h>
#include <spine/spine.h>
#include "spine-cpp-lite.h"

void spine_animation_state_dispose(spine_animation_state state) {
    if (!state) {
        return;
    }
    spine::AnimationState* self = reinterpret_cast<spine::AnimationState*>(state);
    delete self;
}

void spine_skeleton_dispose(spine_skeleton state) {
    if (!state)
        return;
    spine::Skeleton* self = reinterpret_cast<spine::Skeleton*>(state);
    delete self;
}

spine_animation_state_data spine_animation_state_data_create(spine_skeleton_data data) {
    if (!data) {
        return nullptr;
    }
    auto parent = reinterpret_cast<spine::SkeletonData*>(data);
    auto self = new (__FILE__, __LINE__) spine::AnimationStateData(parent);
    return reinterpret_cast<spine_animation_state_data>(self);
}

void spine_animation_state_data_dispose(spine_animation_state_data state) {
    if (!state) {
        return;
    }
    auto self = reinterpret_cast<spine::AnimationStateData*>(state);
    delete self;
}

spine_skeleton spine_skeleton_create(spine_skeleton_data data) {
    if (!data) {
        return nullptr;
    }
    auto parent = reinterpret_cast<spine::SkeletonData*>(data);
    auto self = new (__FILE__, __LINE__) spine::Skeleton(parent);
    return reinterpret_cast<spine_skeleton>(self);
}

spine_animation_state spine_animation_state_create(spine_animation_state_data data) {
    if (!data) {
        return nullptr;
    }
    auto parent = reinterpret_cast<spine::AnimationStateData*>(data);
    auto self = new (__FILE__, __LINE__) spine::AnimationState(parent);
    return reinterpret_cast<spine_animation_state>(self);
}

void* spine_render_command_get_texture(spine_render_command cmd) {
    if (!cmd) {
        return nullptr;
    }
    auto self = reinterpret_cast<spine::RenderCommand*>(cmd);
    return self->texture;
}

spine_skeleton_rect spine_skeleton_current_rect(spine_skeleton _Nonnull skeleton, spine_bool useClipping) {
    if (!skeleton) {
        return spine_skeleton_rect {0,0,0,0};
    }
    spine_skeleton_rect result;
    auto self = reinterpret_cast<spine::Skeleton*>(skeleton);
    auto vector = spine::Vector<float>();
    if (useClipping) {
        auto clipper = spine::SkeletonClipping();
        self->getBounds(result.x, result.y, result.width, result.height, vector, &clipper);
    } else {
        self->getBounds(result.x, result.y, result.width, result.height, vector);
    }

    return result;
}
