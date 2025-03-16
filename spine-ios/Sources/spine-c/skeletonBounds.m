//
//  skeletonBounds.c
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
#include <spine/Skeleton.h>
#include <spine/SkeletonClipping.h>
#include <Foundation/Foundation.h>
#include <spine/extension.h>
#include <CoreGraphics/CGGeometry.h>
#include "spine_public.h"

CGRect spSkeleton_computeBounds(spSkeleton *self, spSkeletonClipping * _Nullable clipper, NSMutableData* outVertex) {
    unsigned short quadIndices[] = {0, 1, 2, 2, 3, 0};
	float minX = FLT_MAX;
	float minY = FLT_MAX;
	float maxX = -FLT_MAX;
	float maxY = -FLT_MAX;

    
    spFloatArray* outVertexBuffer = spFloatArray_create(8);
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
            if (outVertexBuffer->size < 8) {
                spFloatArray_setSize(outVertexBuffer, 8);
			}
            spRegionAttachment_computeWorldVertices(regionAttachment, slot, outVertexBuffer->items, 0, 2);
			triangles = quadIndices;
			trianglesLength = 6;
		} else if (attachment != NULL &&
                   attachment->type == SP_ATTACHMENT_MESH) {
            spMeshAttachment *mesh = SUB_CAST(spMeshAttachment, attachment);

            
            verticesLength = mesh->super.worldVerticesLength;
			if (outVertexBuffer->size < verticesLength) {
                spFloatArray_setSize(outVertexBuffer, verticesLength);
			}

            spVertexAttachment_computeWorldVertices(&mesh->super, slot, 0, verticesLength, outVertexBuffer->items, 0, 2);
			triangles = mesh->triangles;
            
			trianglesLength = mesh->trianglesCount;
		} else if (attachment != NULL &&
                   attachment->type == SP_ATTACHMENT_CLIPPING && clipper != NULL) {
            spSkeletonClipping_clipStart(clipper, slot, SUB_CAST(spClippingAttachment, attachment));
		}

		if (verticesLength > 0) {
           
            float *vertices = outVertexBuffer->items;
			if (clipper != NULL && spSkeletonClipping_isClipping(clipper)) {
                spSkeletonClipping_clipTriangles2(clipper, vertices, outVertexBuffer->size, triangles, trianglesLength);
                
				vertices = clipper->clippedVertices->items;
                
				verticesLength = clipper->clippedVertices->size;
			}
			for (size_t ii = 0; ii < verticesLength; ii += 2) {
				float vx = vertices[ii];
				float vy = vertices[ii + 1];
               
                minX = MIN(minX, vx);
				minY = MIN(minY, vy);
				maxX = MAX(maxX, vx);
				maxY = MAX(maxY, vy);
			}
		}
        if (clipper != NULL) {
            spSkeletonClipping_clipEnd(clipper, slot);
        }
	}
    if (clipper != NULL) {
        spSkeletonClipping_clipEnd2(clipper);
    }
    if (outVertex) {
        [outVertex setLength:(outVertexBuffer->size) * sizeof(float)];
        memcpy(outVertex.mutableBytes, outVertexBuffer->items, outVertexBuffer->size * sizeof(float));
    }

    spFloatArray_dispose(outVertexBuffer);
    outVertexBuffer = NULL;

    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}


void spSkeletonClipping_clipTriangles2(spSkeletonClipping *self, float *vertices, int verticesLength,
                                       unsigned short *triangles, int trianglesLength) {
    
    spFloatArray* uvDummy = spFloatArray_create(verticesLength);
    spFloatArray_setSize(uvDummy, verticesLength);
    spSkeletonClipping_clipTriangles(self, vertices, verticesLength, triangles, trianglesLength, uvDummy->items, 2);
    spFloatArray_dispose(uvDummy);
    uvDummy = NULL;
}
