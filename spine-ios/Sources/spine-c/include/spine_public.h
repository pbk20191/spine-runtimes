//
//  spine_public.h
//  spine-ios
//
//  Created by 박병관 on 3/15/25.
//

#ifndef spine_public_h
#define spine_public_h

struct spSkeleton;
struct CGRect;
struct spSkeletonClipping;
struct spFloatArray;
struct spUnsignedShortArray;
struct spShortArray;
//struct RenderCommandBlock;
#include <CoreFoundation/CoreFoundation.h>
#include <spine/Array.h>
#include <spine/SlotData.h>



CF_ASSUME_NONNULL_BEGIN


CF_EXTERN_C_BEGIN

void spSkeletonClipping_clipTriangles2(struct spSkeletonClipping *self, float *vertices, int verticesLength,
                                      unsigned short *triangles, int trianglesLength);

CGRect spSkeleton_computeBounds(struct spSkeleton *self,struct spSkeletonClipping * _Nullable clipper, CFMutableDataRef _Nullable outVertex);


typedef struct {
    float* positions;
    CFIndex positionCount;
    float* uvs;
    CFIndex uvCount;
    int* colors;
    CFIndex colorCount;
    unsigned short* indices;
    CFIndex indexCount;
    CFIndex pageIndex;
    spBlendMode blendMode;
    bool pma;
    const char* pageName;
} SpineRenderBatchCommand;

typedef void (*SpineRenderBatchCommandHandler)(const SpineRenderBatchCommand* _Nullable buffer, CFIndex count, void* _Nullable context);


void spSkeleton_render(struct spSkeleton * self, struct spSkeletonClipping * clipping, SpineRenderBatchCommandHandler function, void * _Nullable context);

CF_EXTERN_C_END
CF_ASSUME_NONNULL_END

#endif /* spine_public_h */
