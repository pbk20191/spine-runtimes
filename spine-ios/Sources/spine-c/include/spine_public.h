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
@class NSNumber;
@class NSMutableArray;
struct spFloatArray;
struct spUnsignedShortArray;
struct spShortArray;
//struct RenderCommandBlock;
#include <Foundation/Foundation.h>
#include <spine/Array.h>
#include <spine/SlotData.h>
NS_ASSUME_NONNULL_BEGIN


void spSkeletonClipping_clipTriangles2(struct spSkeletonClipping *self, float *vertices, int verticesLength,
                                      unsigned short *triangles, int trianglesLength);

CGRect spSkeleton_computeBounds(struct spSkeleton *self,struct spSkeletonClipping * _Nullable clipper, NSMutableData* _Nullable outVertex);


@protocol SpineCRenderCommand <NSObject>

@property (readonly) const float *positions;
@property (readonly) const NSInteger positionCount;
@property (readonly) const float *uvs;
@property (readonly) const NSInteger uvCount;
@property (readonly) const int *colors;
@property (readonly) const NSInteger colorCount;
@property (readonly) const unsigned short *indices;
@property (readonly) const NSInteger indexCount;
@property (readonly) spBlendMode blendMode;
@property (readonly) int textureIndex;
@property (readonly) bool pma;
@property (readonly) NSString* pageName;

@end


NSArray<id<SpineCRenderCommand>>* spSkeleton_render(struct spSkeleton * self, struct spSkeletonClipping * clipping);

NS_ASSUME_NONNULL_END

#endif /* spine_public_h */
