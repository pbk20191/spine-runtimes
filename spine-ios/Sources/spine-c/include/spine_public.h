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
#include <CoreGraphics/CoreGraphics.h>
CF_ASSUME_NONNULL_BEGIN

CF_EXTERN_C_BEGIN

typedef struct {
    int color;
    int darkColor;
    bool hasDark;
} spRenderColor;

typedef struct {
    float* positions;
    CFIndex positionCount;
    float* uvs;
    CFIndex uvCount;
    spRenderColor* colors;
    CFIndex colorCount;
    unsigned short* indices;
    CFIndex indexCount;
    CFIndex pageIndex;
    spBlendMode blendMode;
    bool pma;
    const char* pageName;
} SpineRenderBatchCommand;

SP_API
CF_RETURNS_RETAINED
CGPathRef spSkeleton_createBoundingPath( spSkeleton *self, spSkeletonClipping * _Nullable clipper);


typedef void (*SpineRenderBatchCommandHandler)(const SpineRenderBatchCommand* _Nullable buffer, CFIndex count, void* _Nullable context);

SP_API
void spSkeleton_render( spSkeleton * self,  spSkeletonClipping * clipping, SpineRenderBatchCommandHandler function, void * _Nullable context);

CF_EXTERN_C_END
CF_ASSUME_NONNULL_END

#endif /* spine_public_h */
