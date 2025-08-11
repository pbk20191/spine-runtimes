//
//  SpineTextureLoaderContext.swift
//  spine-ios
//
//  Created by 박병관 on 8/11/25.
//


//
//  texture_loader.h
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#ifndef texture_loader_h
#define texture_loader_h

#include "spine-cpp-lite.h"
#include <spine-c/atlas.h>
#define SPINE_C_API SPINE_CPP_LITE_EXPORT

SPINE_OPAQUE_TYPE(spine_texture_loader)

SPINE_C_API void spine_texture_loader_dispose(spine_texture_loader _Nonnull loader);

SPINE_C_API spine_atlas2 _Nonnull spine_atlas2_create(const char *__null_terminated _Nonnull path, spine_texture_loader _Nonnull textureLoader,
												  bool createTexture);
SPINE_C_API spine_atlas2 _Nonnull spine_atlas2_create_from_data(const char *__counted_by(length) _Nonnull data, int length,
													const char *__null_terminated _Nullable dir, spine_texture_loader _Nonnull textureLoader,
													bool createTexture);


#endif /* texture_loader_h */
