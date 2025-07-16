//
//  texture_loader.h
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#ifndef texture_loader_h
#define texture_loader_h

#include "src/generated/types.h"
#include "src/base.h"

SPINE_OPAQUE_TYPE(spine_texture_loader);

#ifndef __counted_by
#define __counted_by(length)
#endif

#ifndef __null_terminated
#define __null_terminated
#endif

typedef struct {
    void* _Nullable  (* _Nullable initialize)(const void* _Nullable input);
    void (* _Nullable deinitialize)(void* _Nullable loader);
    void (* _Nullable load)(spine_atlas_page _Nonnull  page, const char* __null_terminated _Nonnull path, void* _Nullable context);
    void (* _Nullable unload)(void* _Nullable texture, void* _Nullable context);
    void* _Nullable info;
} SpineTextureLoaderContext;

SPINE_C_API spine_texture_loader _Nonnull spine_texture_loader_create(const SpineTextureLoaderContext* _Nonnull vtable);
SPINE_C_API void spine_texture_loader_dispose(spine_texture_loader _Nonnull loader);

SPINE_C_API spine_atlas _Nonnull spine_atlas_load(const char* __null_terminated _Nonnull path, spine_texture_loader _Nonnull textureLoader, bool createTexture);
SPINE_C_API spine_atlas _Nonnull spine_atlas_create(const char* __counted_by(length) _Nonnull data, int length, const char* __null_terminated _Nullable dir, spine_texture_loader _Nonnull textureLoader, bool createTexture);

#endif /* texture_loader_h */
