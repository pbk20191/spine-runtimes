#ifndef SPINE_SPINE_SKELETON_RENDERER_H
#define SPINE_SPINE_SKELETON_RENDERER_H

#include "spine-cpp-lite.h"

SPINE_OPAQUE_TYPE(spine_skeleton_renderer);
#ifdef __cplusplus
extern "C" {
#endif

#define SPINE_C_API SPINE_CPP_LITE_EXPORT


SPINE_C_API spine_skeleton_renderer spine_skeleton_renderer_create(void);

SPINE_C_API void spine_skeleton_renderer_dispose(spine_skeleton_renderer self);

SPINE_C_API spine_render_command spine_skeleton_renderer_render(spine_skeleton_renderer self, spine_skeleton skeleton);

#ifdef __cplusplus
}
#endif

#endif /* SPINE_SPINE_SKELETON_RENDERER_H */
