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
    unsigned short quadIndices[] = {0, 1, 2, 2, 3, 0};


    spFloatArray* vertexBuffer = spFloatArray_create(8);
    spFloatArray* uvBuffer = spFloatArray_create(32);
    CGMutablePathRef path = CGPathCreateMutable();
	for (size_t i = 0; i < self->slotsCount; ++i) {
        spSlot *slot = self->drawOrder[i];
        if (!slot->bone->active)
			continue;
		int verticesLength = 0;
        spAttachment *attachment = slot->attachment;
		unsigned short *triangles = NULL;
        int trianglesLength = 0;

		if (attachment != NULL &&
            attachment->type == SP_ATTACHMENT_REGION) {
            spRegionAttachment *regionAttachment = SUB_CAST(spRegionAttachment, attachment);
			verticesLength = 8;
            
            if (vertexBuffer->size < verticesLength) {
                spFloatArray_setSize(vertexBuffer, verticesLength);
			}
            
            spRegionAttachment_computeWorldVertices(regionAttachment, slot, vertexBuffer->items, 0, 2);
			triangles = quadIndices;
			trianglesLength = 6;
		} else if (attachment != NULL &&
                   attachment->type == SP_ATTACHMENT_MESH) {
            spMeshAttachment *mesh = SUB_CAST(spMeshAttachment, attachment);

            
            verticesLength = mesh->super.worldVerticesLength;
            if (vertexBuffer->size < verticesLength) {
                spFloatArray_setSize(vertexBuffer, verticesLength);
			}

            spVertexAttachment_computeWorldVertices(&mesh->super, slot, 0, verticesLength, vertexBuffer->items, 0, 2);
			triangles = mesh->triangles;
            
			trianglesLength = mesh->trianglesCount;
		} else if (attachment != NULL &&
                   attachment->type == SP_ATTACHMENT_CLIPPING && clipper != NULL) {
            spSkeletonClipping_clipStart(clipper, slot, SUB_CAST(spClippingAttachment, attachment));
		}

		if (verticesLength > 0) {
            
            float *vertices = vertexBuffer->items;
			if (clipper != NULL && spSkeletonClipping_isClipping(clipper)) {
                
                spSkeletonClipping_clipTriangles2(clipper, vertices, vertexBuffer->size, triangles, trianglesLength, uvBuffer);
                
				vertices = clipper->clippedVertices->items;
                
				verticesLength = clipper->clippedVertices->size;
			}
            // add triagles to CGPath
            for (int t = 0; t < trianglesLength; t += 3) {
                int i0 = triangles[t] * 2;
                int i1 = triangles[t + 1] * 2;
                int i2 = triangles[t + 2] * 2;

                CGPoint p0 = CGPointMake(vertices[i0], vertices[i0 + 1]);
                CGPoint p1 = CGPointMake(vertices[i1], vertices[i1 + 1]);
                CGPoint p2 = CGPointMake(vertices[i2], vertices[i2 + 1]);

                CGPathMoveToPoint(path, NULL, p0.x, p0.y);
                CGPathAddLineToPoint(path, NULL, p1.x, p1.y);
                CGPathAddLineToPoint(path, NULL, p2.x, p2.y);
                CGPathCloseSubpath(path);
            }
		}
        if (clipper != NULL) {
            spSkeletonClipping_clipEnd(clipper, slot);
        }
    }
    if (clipper != NULL) {
        spSkeletonClipping_clipEnd2(clipper);
    }
    spFloatArray_dispose(vertexBuffer);
    spFloatArray_dispose(uvBuffer);
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
