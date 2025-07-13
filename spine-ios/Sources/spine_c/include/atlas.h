#ifndef SPINE_SPINE_ATLAS_H
#define SPINE_SPINE_ATLAS_H

#include "spine-cpp-lite.h"
#include "arrays.h"

SPINE_OPAQUE_TYPE(spine_atlas2);

#ifdef __cplusplus
extern "C" {
#endif

SPINE_CPP_LITE_EXPORT void spine_atlas2_dispose(spine_atlas2 _Nonnull self);

SPINE_CPP_LITE_EXPORT void spine_atlas2_flip_v(spine_atlas2 _Nonnull self);
SPINE_CPP_LITE_EXPORT spine_array_atlas_page _Nullable spine_atlas2_get_pages(spine_atlas2 _Nonnull self);


SPINE_CPP_LITE_EXPORT spine_atlas2 _Nonnull spine_atlas2_create(const char * _Nonnull path);
SPINE_CPP_LITE_EXPORT spine_atlas2 _Nonnull spine_atlas2_create_from_data(const char* __counted_by(length) _Nonnull strdata, int length, const char* _Nullable dir);

// SPINE_CPP_LITE_EXPORT spine_atlas2 _Nonnull spine_atlas_get_native(spine_atlas _Nonnull self);


#ifdef __cplusplus
}
#endif

#endif /* SPINE_SPINE_ATLAS_H */
