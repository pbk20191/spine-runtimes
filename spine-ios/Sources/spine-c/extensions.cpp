//
//  extension.c
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#include "src/extensions.h"
#include <spine/spine.h>
#include <spine/Version.h>
#include <spine/Debug.h>

#if __BLOCKS__

#if __has_include(<Block.h>)
#include <Block.h>
#else
extern "C" {
    void *_Block_copy(const void *block);
    void _Block_release(const void *block);
}

#define Block_copy(x) ((__typeof(x))_Block_copy((const void *)(x)))
#define Block_release(x) _Block_release((const void *)(x))
#endif

namespace {

template <typename T>
struct BlockFunctionTraits;

template <typename R, typename... Args>
struct BlockFunctionTraits<R (^)(Args...)> {
    using Signature = R(Args...);
};


template<typename BlockType>
static inline BlockType SafeBlockCopy(BlockType block) {
    if (block) {
        return Block_copy(block);
    }
    return reinterpret_cast<BlockType>(block);
}

template<typename BlockType>
static inline void SafeBlockRelease(BlockType block) {
    if (block) {
        Block_release(block);
    }
}


template <typename Signature>
class BlockWrapper;

template <typename R, typename... Args>
class BlockWrapper<R(Args...)> {
    using BlockType = R (^)(Args...);
private:
    BlockType block_ = nullptr;

public:
    // constructor
    explicit BlockWrapper(R (^block)(Args...))
        : block_(SafeBlockCopy(block)) {}

    // copy constructor
    BlockWrapper(const BlockWrapper& other)
        : block_(SafeBlockCopy(other.block_)) {}

    // move constructor
    BlockWrapper(BlockWrapper&& other) noexcept
        : block_(other.block_) {
            other.block_ = nullptr;
    }

    // copy assignment
    BlockWrapper& operator=(const BlockWrapper& other) {
        if (this != &other) {
            SafeBlockRelease(block_);
            block_ = SafeBlockCopy(other.block_);
        }
        return *this;
    }

    // move assignment
    BlockWrapper& operator=(BlockWrapper&& other) noexcept {
        if (this != &other) {
            SafeBlockRelease(block_);
            block_ = other.block_;
            other.block_ = nullptr;
        }
        return *this;
    }

    // destructor
    ~BlockWrapper() {
        SafeBlockRelease(block_);
    }
    
    BlockType get() const {
        return block_;
    }
};

template <typename BlockType>
inline BlockWrapper<typename BlockFunctionTraits<BlockType>::Signature> MakeBlockWrapper(BlockType block) {
    return BlockWrapper<typename BlockFunctionTraits<BlockType>::Signature>(block);
}


static inline void release_block(void* ptr) {
    auto block = reinterpret_cast<SpineAnimationCallbackBlock>(ptr);
    SafeBlockRelease(block);
}

template <typename Base>
struct BlockSelector;

template <>
struct BlockSelector<spine::TrackEntry> {
    static SpineAnimationCallbackBlock select(spine::AnimationState*, spine::TrackEntry* entry) {
        return reinterpret_cast<SpineAnimationCallbackBlock>(entry->getRendererObject());
    }
};

template <>
struct BlockSelector<spine::AnimationState> {
    static SpineAnimationCallbackBlock select(spine::AnimationState* state, spine::TrackEntry*) {
        return reinterpret_cast<SpineAnimationCallbackBlock>(state->getRendererObject());
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
        auto wrapper = MakeBlockWrapper(block);
        self->setListener([wrapper](spine::AnimationState* state, spine::EventType type, spine::TrackEntry *trackEntry, spine::Event *event) {
            auto block = wrapper.get();
            block(
                  reinterpret_cast<spine_animation_state>(state),
                  static_cast<spine_event_type>(type),
                  reinterpret_cast<spine_track_entry>(trackEntry),
                  reinterpret_cast<spine_event>(event)
                  );
        });
#else
        auto wrapper = reinterpret_cast<void*>(SafeBlockCopy(block));
        self->setRendererObject(wrapper, release_block);
        self->setListener(dispatch_block_callback<Base>);
#endif
    }
}


} // namespace


void spine_track_entry_set_block(spine_track_entry entry, SpineAnimationCallbackBlock block) {
    auto self = reinterpret_cast<spine::TrackEntry *>(entry);
    spine_set_block(self, block);
}

void spine_animation_state_set_block(spine_animation_state state, SpineAnimationCallbackBlock block) {
    auto self = reinterpret_cast<spine::AnimationState *>(state);
    spine_set_block(self, block);
}

#endif

int32_t spine_major_version(void) {
    return SPINE_MAJOR_VERSION;
}

int32_t spine_minor_version(void) {
    return SPINE_MINOR_VERSION;
}

namespace {

class SpineDelegateExtension : public spine::SpineExtension {
    
public:
    spine::SpineExtension *imp;
    
    SpineDelegateExtension(spine::SpineExtension *imp) : imp(imp), spine::SpineExtension() {}
    
    SpineDelegateExtension(): SpineDelegateExtension(nullptr) {}
    
    void * _alloc(size_t size, const char *file, int line) override {
        return imp->_alloc(size, file, line);
    }
    
    void * _realloc(void *ptr, size_t size, const char *file, int line) override {
        return imp->_realloc(ptr, size, file, line);
    }
    void * _calloc(size_t size, const char *file, int line) override {
        return imp->_calloc(size, file, line);
    }
    void _free(void *mem, const char *file, int line) override {
        imp->_free(mem, file, line);
    }
    char* _readFile(const spine::String &path, int *length) override {
        return imp->_readFile(path, length);
    }
    
    void _beforeFree(void *ptr) override {
        imp->_beforeFree(ptr);
    }
    
};

class SpineDebugExtension : public spine::DebugExtension {
private:
    spine::SpineExtension *imp;
public:
    
    SpineDebugExtension(spine::SpineExtension *imp) : imp(imp), spine::DebugExtension(imp) {}
    
    void _beforeFree(void *ptr) override {
        imp->_beforeFree(ptr);
    };
    
};

}

#if defined(__clang__)
  #if __has_feature(cxx_rtti)
    #define RTTI_ENABLED
  #endif
#elif defined(__GNUC__)
  #if defined(__GXX_RTTI)
    #define RTTI_ENABLED
  #endif
#elif defined(_MSC_VER)
  #if defined(_CPPRTTI)
    #define RTTI_ENABLED
  #endif
#endif

static SpineDelegateExtension wrapper;
static auto debugExtension = SpineDebugExtension(&wrapper);


void spine_enable_debug_extension(bool enable) {
    spine::SpineExtension *original = spine::SpineExtension::getInstance();
    if (wrapper.imp != original && original != &debugExtension) {
        wrapper.imp = original;
    }
    if (enable) {
        spine::SpineExtension::setInstance(&debugExtension);
    } else {
        spine::SpineExtension::setInstance(wrapper.imp);
    }
}

void spine_report_leaks(void) {
    auto extension = spine::SpineExtension::getInstance();
#ifdef RTTI_ENABLED
    auto _debugExtension = dynamic_cast<spine::DebugExtension*>(extension);
#else
    auto _debugExtension = static_cast<spine::DebugExtension*>(&debugExtension);
#endif
    if (_debugExtension) {
        _debugExtension->reportLeaks();
        fflush(stdout);
    }
}
