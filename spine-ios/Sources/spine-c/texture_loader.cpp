//
//  texture_loader.c
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#include "spine-c/texture_loader.h"
#include <spine/spine.h>
#include "spine-c/SpineCTextureLoader.hpp"

spine_texture_loader spine_texture_loader_create(const SpineTextureLoaderContext* vtable) {
    if (!vtable) {
        return nullptr;
    }
    
    auto loader = new (__FILE__, __LINE__) spine::SpineCTextureLoader(*vtable);
    return reinterpret_cast<spine_texture_loader>(loader);
}

void spine_texture_loader_dispose(spine_texture_loader loader) {
    if (!loader) {
        return;
    }
    auto self = reinterpret_cast<spine::TextureLoader*>(loader);
    delete self;
}

spine_atlas spine_atlas_load(const char* path, spine_texture_loader textureLoader, bool createTexture) {
    if (!path) {
        return nullptr;
    }
    auto loader = reinterpret_cast<spine::TextureLoader*>(textureLoader);
    auto native = new (__FILE__, __LINE__) spine::Atlas(path, loader, createTexture);
    return reinterpret_cast<spine_atlas>(native);
}

spine_atlas spine_atlas_create(const char* _Nonnull data, int length, const char* dir, spine_texture_loader _Nonnull textureLoader, bool createTexture) {
    if (!data || length <= 0) {
        return nullptr;
    }
    const char* empty_dir = "";
    const char* dir_to_use = dir ? dir : empty_dir;
    auto loader = reinterpret_cast<spine::TextureLoader*>(textureLoader);
    auto native = new (__FILE__, __LINE__) spine::Atlas(data, length, dir_to_use, loader, createTexture);
    return reinterpret_cast<spine_atlas>(native);
}
