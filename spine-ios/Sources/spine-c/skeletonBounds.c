//
//  skeletonBounds.c
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
#include <spine/spine.h>
#include <spine/extension.h>
#include "spine_public.h"

CF_INLINE void spSkeletonClipping_clipTriangles2( spSkeletonClipping *self, float *vertices, int verticesLength,
                                      unsigned short *triangles, int trianglesLength,spFloatArray* uv);

CF_RETURNS_RETAINED
CGPathRef spSkeleton_createBoundingPath(spSkeleton *self, spSkeletonClipping * _Nullable clipper) {
    spFloatArray *_worldVertices = spFloatArray_create(32);
    const unsigned short quadIndices[] = {0, 1, 2, 2, 3, 0};
    float region_vertices[] = {0,0,0,0,0,0,0,0};
    spFloatArray uvsHolder = {0,0,0};
    spUnsignedShortArray indicesHolder = {0,0,0};


    CGMutablePathRef path = CGPathCreateMutable();
    for (size_t i = 0; i < self->slotsCount; ++i) {
        spSlot *slot = self->drawOrder[i];
        if (!slot->bone->active)
            continue;
        spAttachment *attachment = slot->attachment;
        if (!attachment) {
            if (clipper) {
                spSkeletonClipping_clipEnd(clipper, slot);
            }
            continue;
        }
        if ((slot->color.a == 0 || !slot->bone->active) && attachment->type != SP_ATTACHMENT_CLIPPING) {
            if (clipper) {
                spSkeletonClipping_clipEnd(clipper, slot);
            }
            continue;
        }
        
        spFloatArray *vertices = _worldVertices;
        spFloatArray *uvs = &uvsHolder;
        spUnsignedShortArray *indices = &indicesHolder;
        int32_t verticesCount = 0;

        if (attachment->type == SP_ATTACHMENT_REGION) {
            spRegionAttachment *regionAttachment = SUB_CAST(spRegionAttachment, attachment);
            if (regionAttachment->color.a == 0) {
                if (clipper) {
                    spSkeletonClipping_clipEnd(clipper, slot);
                }
                continue;
            }
            spFloatArray_setSize(vertices, 8);
            spRegionAttachment_computeWorldVertices(regionAttachment, slot, vertices->items, 0, 2);
            *uvs = (spFloatArray){
                .items = regionAttachment->uvs,
                .size = 8,
                .capacity = 8
            };
            verticesCount = 4;

            *indices = (spUnsignedShortArray){
                .items = (unsigned short*) quadIndices,
                .size = 6,
                .capacity = 6
            };
        } else if (attachment->type == SP_ATTACHMENT_MESH) {
            spMeshAttachment *mesh = SUB_CAST(spMeshAttachment, attachment);

            if (mesh->color.a == 0) {
                if (clipper) {
                    spSkeletonClipping_clipEnd(clipper, slot);
                }
                continue;
            }
            spFloatArray_setSize(vertices,mesh->super.worldVerticesLength);
            spVertexAttachment_computeWorldVertices(&mesh->super, slot, 0, mesh->super.worldVerticesLength, vertices->items, 0, 2);
            *uvs = (spFloatArray){
                .items = mesh->uvs,
                .size = mesh->super.worldVerticesLength,
                .capacity = mesh->super.worldVerticesLength,
            };
            verticesCount = (int32_t) (mesh->super.worldVerticesLength >> 1);
            *indices = (spUnsignedShortArray){
                .items = mesh->triangles,
                .size = mesh->trianglesCount,
                .capacity = mesh->trianglesCount
            };
        } else if (attachment->type == SP_ATTACHMENT_CLIPPING && clipper != NULL) {
            spClippingAttachment *clip = SUB_CAST(spClippingAttachment, attachment);
            spSkeletonClipping_clipStart(clipper, slot, clip);
            continue;
        } else {
            continue;
        }

        if (clipper != NULL && spSkeletonClipping_isClipping(clipper)) {
            spSkeletonClipping_clipTriangles(clipper, vertices->items, verticesCount, indices->items, indices->size, uvs->items, 2);
            vertices = clipper->clippedVertices;
            uvs = clipper->clippedUVs;
            indices = clipper->clippedTriangles;
            verticesCount = clipper->clippedVertices->size >> 1;
        }
        // add triagles to CGPath
        for (int t = 0; t < indices->size; t += 3) {
            int i0 = indices->items[t] * 2;
            int i1 = indices->items[t + 1] * 2;
            int i2 = indices->items[t + 2] * 2;

            CGPoint p0 = CGPointMake(vertices->items[i0], vertices->items[i0 + 1]);
            CGPoint p1 = CGPointMake(vertices->items[i1], vertices->items[i1 + 1]);
            CGPoint p2 = CGPointMake(vertices->items[i2], vertices->items[i2 + 1]);

            CGPathMoveToPoint(path, NULL, p0.x, p0.y);
            CGPathAddLineToPoint(path, NULL, p1.x, p1.y);
            CGPathAddLineToPoint(path, NULL, p2.x, p2.y);
            CGPathCloseSubpath(path);
        }
        if (clipper) {
            spSkeletonClipping_clipEnd(clipper, slot);
        }
    }
    if (clipper) {
        spSkeletonClipping_clipEnd2(clipper);
    }
    spFloatArray_dispose(_worldVertices);
    CGPathRef final = CGPathCreateCopy(path);
    CFRelease(path);
    path = NULL;
    return final;

}

CF_INLINE
void spSkeletonClipping_clipTriangles2(spSkeletonClipping *self, float *vertices, int verticesLength,
                                       unsigned short *triangles, int trianglesLength, spFloatArray* uvDummy) {
    
    spFloatArray_setSize(uvDummy, verticesLength);
    spSkeletonClipping_clipTriangles(self, vertices, verticesLength, triangles, trianglesLength, uvDummy->items, 2);

}
