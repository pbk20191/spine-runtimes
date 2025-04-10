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
    const float* positions;
    CFIndex positionCount;
    const float* uvs;
    CFIndex uvCount;
    const unsigned short* indices;
    CFIndex indexCount;
    spBlendMode blendMode;
    // spAtlasRegion
    const void* renderer;
    const spSlot* slot;
} SpineRenderCommandBlock;


typedef void (*SpineRenderBatchCommandHandler)(const SpineRenderCommandBlock* cmd, void* _Nullable context);

SP_API
void spSkeleton_render( spSkeleton * self,  spSkeletonClipping * _Nullable clipping, SpineRenderBatchCommandHandler function, void * _Nullable context);

CF_EXTERN_C_END
CF_ASSUME_NONNULL_END

#endif /* spine_public_h */
