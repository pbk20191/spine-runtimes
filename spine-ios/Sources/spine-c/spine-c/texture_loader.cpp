//
//  texture_loader.cpp
//  spine-ios
//
//  Created by 박병관 on 8/11/25.
//

#include <spine-c/texture_loader.h>
#include <spine/spine.h>

void spine_texture_loader_dispose(spine_texture_loader _Nonnull loader) {
    if (!loader) return;
    auto imp = reinterpret_cast<spine::TextureLoader*>(loader);
    delete imp;
}

spine_atlas2 spine_atlas2_create(const char * _Nonnull path, spine_texture_loader textureLoader,
                                                    bool createTexture) {
    if (!path || !textureLoader) {
        return nullptr;
    }
    auto loader = reinterpret_cast<spine::TextureLoader*>(textureLoader);
    auto atlas = new (__FILE__, __LINE__) spine::Atlas(path, loader, createTexture);
    return reinterpret_cast<spine_atlas2>(atlas);
}

spine_atlas2 spine_atlas2_create_from_data(const char * data, int length,
                                                    const char * dir, spine_texture_loader textureLoader,
                                bool createTexture) {
    if (!data || !textureLoader) {
        return nullptr;
    }
    auto loader = reinterpret_cast<spine::TextureLoader*>(textureLoader);
    auto dirStr = dir ? dir : "";
    auto atlas = new (__FILE__, __LINE__) spine::Atlas(data, length, dirStr, loader, createTexture);
    return reinterpret_cast<spine_atlas2>(atlas);
}
