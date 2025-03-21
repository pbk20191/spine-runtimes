//
//  spine_public.h
//  spine-ios
//
//  Created by 박병관 on 3/15/25.
//

#ifndef spine_public_h
#define spine_public_h


#include <CoreFoundation/CoreFoundation.h>
#include <spine/SlotData.h>
#include <spine/SkeletonClipping.h>
#include <spine/Skeleton.h>

CF_ASSUME_NONNULL_BEGIN

CF_EXTERN_C_BEGIN

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


typedef struct {
    float minX;
    float minY;
    float maxX;
    float maxY;
} SpineMinMaxRect;

void spSkeletonClipping_clipTriangles2( spSkeletonClipping *self, float *vertices, int verticesLength,
                                      unsigned short *triangles, int trianglesLength);

SpineMinMaxRect spSkeleton_computeMinMaxRect( spSkeleton *self, spSkeletonClipping * _Nullable clipper, CFMutableDataRef _Nullable outVertex);


typedef void (*SpineRenderBatchCommandHandler)(const SpineRenderBatchCommand* _Nullable buffer, CFIndex count, void* _Nullable context);


void spSkeleton_render( spSkeleton * self,  spSkeletonClipping * clipping, SpineRenderBatchCommandHandler function, void * _Nullable context);

CF_EXTERN_C_END
CF_ASSUME_NONNULL_END

#endif /* spine_public_h */
