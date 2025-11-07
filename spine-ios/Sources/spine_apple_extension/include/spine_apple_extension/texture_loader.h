//
//  texture_loader.h
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#ifndef texture_loader_h
#define texture_loader_h

#include <spine-c.h>

//SPINE_OPAQUE_TYPE(spine_texture_loader)
//SPINE_FORWARD_OPAQUE_TYPE(spine_atlas)
struct SpineTextureLoaderContext;

SPINE_C_API spine_texture_loader _Nonnull spine_texture_loader_create(const struct SpineTextureLoaderContext *_Nonnull vtable);
SPINE_C_API void spine_texture_loader_dispose(spine_texture_loader _Nonnull loader);

SPINE_C_API spine_atlas _Nonnull spine_atlas_load_with_loader(const char *__null_terminated _Nonnull path, spine_texture_loader _Nonnull textureLoader,
												  bool createTexture);
SPINE_C_API spine_atlas _Nonnull spine_atlas_create_with_loader(const char *__counted_by(length) _Nonnull data, int length,
													const char *__null_terminated _Nullable dir, spine_texture_loader _Nonnull textureLoader,
													bool createTexture);

#endif /* texture_loader_h */
