//
//  patch_file.cpp
//  spine-ios
//
//  Created by 박병관 on 7/12/25.
//
#include "spine_patch.h"
#include <spine/spine.h>
#include <spine/Debug.h>
#include "spine-cpp-lite.h"
#include <functional>

#if __OBJC__
#import <Foundation/Foundation.h>
#endif



#undef spine_report_leaks

#ifdef spine_enable_debug_extension
#undef spine_enable_debug_extension
#endif

typedef struct _spine_atlas {
    void *atlas;
    utf8 **imagePaths;
    int32_t numImagePaths;
    utf8 *error;
} _spine_atlas;

SPINE_CPP_LITE_EXPORT void spine_report_leaks() {
    auto extension = spine::SpineExtension::getInstance();
    auto debugger = dynamic_cast<spine::DebugExtension*>(extension);
    if (debugger) {
        debugger->reportLeaks();
    }
}

SPINE_CPP_LITE_EXPORT void spine_enable_debug_extension(spine_bool enable) {

    class DelegatingExtension: public spine::SpineExtension {
        
        public:
        DelegatingExtension():extension(nil) {}
        
        void * _alloc(size_t size, const char *file, int line) override {
            return extension->_alloc(size, file, line);
        }
        
        void _beforeFree(void *ptr) override {
            return extension->_beforeFree(ptr);
        }
        
        void * _realloc(void *ptr, size_t size, const char *file, int line) override {
            return extension->_realloc(ptr, size, file, line);
        }
        
        void _free(void *mem, const char *file, int line) override {
            return extension->_free(mem, file, line);
        }
        
        char * _readFile(const spine::String &path, int *length) override {
            return extension->_readFile(path, length);
        }
        
        void * _calloc(size_t size, const char *file, int line) override {
            return extension->_calloc(size, file, line);
        }
        
    public:
        spine::SpineExtension *extension;
    };
    static DelegatingExtension extension;
    class DynamicDebugExtension: public spine::DebugExtension {
        public: DynamicDebugExtension():spine::DebugExtension(&extension) {}
    };
    static DynamicDebugExtension debugExtension;
    spine::SpineExtension* original = spine::SpineExtension::getInstance();
    if (!extension.extension) {
        extension.extension = original;
    }
    
    spine::SpineExtension::setInstance(enable ? static_cast<spine::SpineExtension*>(&debugExtension) : extension.extension);
    
}


static void block_listener(spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event) {
    @autoreleasepool {
        SpineAnimationCallbackBlock block = (__bridge SpineAnimationCallbackBlock) state->getRendererObject();
        block(
              reinterpret_cast<spine_animation_state>(state),
              static_cast<spine_event_type>(type),
              reinterpret_cast<spine_track_entry>(entry),
              reinterpret_cast<spine_event>(event)
              );
    }
}

typedef void (*_DisposeRendererObject)(void *rendererObject);

void spine_animation_state_set_block(spine_animation_state state, SpineAnimationCallbackBlock block) {
    if (!state) {
        return;
    }
    spine::AnimationState* self = reinterpret_cast<spine::AnimationState*>(state);
    if (block) {
#ifdef SPINE_USE_STD_FUNCTION
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
        self->setListener(block_listener);
        auto release_block = reinterpret_cast<_DisposeRendererObject>(CFRelease);
        self->setRendererObject((__bridge_retained void*) block, release_block);
#endif

    } else {
        spine::AnimationStateListenerObject* ref = nil;
        self->setListener(ref);
#ifndef SPINE_USE_STD_FUNCTION
        self->setRendererObject(nil);
#endif
    }
}

void spine_track_entry_set_block(spine_track_entry entry, SpineAnimationCallbackBlock block) {
    if (!entry) {
        return;
    }
    spine::TrackEntry* self = reinterpret_cast<spine::TrackEntry*>(entry);
    if (block) {
#ifdef SPINE_USE_STD_FUNCTION
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
        self->setListener(block_listener);
        auto release_block = reinterpret_cast<_DisposeRendererObject>(CFRelease);
        self->setRendererObject((__bridge_retained void*) block, release_block);
#endif
    } else {
        spine::AnimationStateListenerObject* ref = nil;
        self->setListener(ref);
#ifndef SPINE_USE_STD_FUNCTION
        self->setRendererObject(nil);
#endif
    }
}

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
        return nil;
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
        return nil;
    }
    auto parent = reinterpret_cast<spine::SkeletonData*>(data);
    auto self = new (__FILE__, __LINE__) spine::Skeleton(parent);
    return reinterpret_cast<spine_skeleton>(self);
}

spine_animation_state spine_animation_state_create(spine_animation_state_data data) {
    if (!data) {
        return nil;
    }
    auto parent = reinterpret_cast<spine::AnimationStateData*>(data);
    auto self = new (__FILE__, __LINE__) spine::AnimationState(parent);
    return reinterpret_cast<spine_animation_state>(self);
}

void* spine_render_command_get_texture(spine_render_command cmd) {
    if (!cmd) {
        return nil;
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

#ifdef __OBJC__



#endif
