//
//  skeletonBounds.c
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//
#include <spine/spine.h>
#include <spine/extension.h>
#include "spine_public.h"
#include <simd/simd.h>

SpineMinMaxRect spSkeleton_computeMinMaxRect(spSkeleton *self, spSkeletonClipping * _Nullable clipper, CFMutableDataRef outVertex) {
    unsigned short quadIndices[] = {0, 1, 2, 2, 3, 0};
    simd_float2 minValue = simd_make_float2(FLT_MAX, FLT_MAX);
    
    simd_float2 maxValue = -minValue;

    const bool releaseData = outVertex == nil;
    
#define ELEMENTBYTE sizeof(float)

    if (!outVertex) {
        outVertex = CFDataCreateMutable(kCFAllocatorDefault, 0);
    }
    CFDataSetLength(outVertex, 8 * ELEMENTBYTE);
    
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
            
            if (CFDataGetLength(outVertex) < 8 * ELEMENTBYTE) {
                CFDataSetLength(outVertex, 8 * ELEMENTBYTE);
			}
            
            spRegionAttachment_computeWorldVertices(regionAttachment, slot, (float *)CFDataGetMutableBytePtr(outVertex), 0, 2);
			triangles = quadIndices;
			trianglesLength = 6;
		} else if (attachment != NULL &&
                   attachment->type == SP_ATTACHMENT_MESH) {
            spMeshAttachment *mesh = SUB_CAST(spMeshAttachment, attachment);

            
            verticesLength = mesh->super.worldVerticesLength;
            if (CFDataGetLength(outVertex) < verticesLength*ELEMENTBYTE) {
                CFDataSetLength(outVertex, verticesLength*ELEMENTBYTE);

			}

            spVertexAttachment_computeWorldVertices(&mesh->super, slot, 0, verticesLength, (float *)CFDataGetMutableBytePtr(outVertex), 0, 2);
			triangles = mesh->triangles;
            
			trianglesLength = mesh->trianglesCount;
		} else if (attachment != NULL &&
                   attachment->type == SP_ATTACHMENT_CLIPPING && clipper != NULL) {
            spSkeletonClipping_clipStart(clipper, slot, SUB_CAST(spClippingAttachment, attachment));
		}

		if (verticesLength > 0) {
            
            float *vertices = (float *) CFDataGetBytePtr(outVertex);
			if (clipper != NULL && spSkeletonClipping_isClipping(clipper)) {
                
                spSkeletonClipping_clipTriangles2(clipper, vertices, CFDataGetLength(outVertex)/ELEMENTBYTE, triangles, trianglesLength);
                
				vertices = clipper->clippedVertices->items;
                
				verticesLength = clipper->clippedVertices->size;
			}
			for (size_t ii = 0; ii < verticesLength; ii += 2) {
                simd_float2 v = simd_make_float2(vertices[ii], vertices[ii + 1]);
                minValue = simd_min(minValue, v);
                maxValue = simd_max(maxValue, v);
			}
		}
        if (clipper != NULL) {
            spSkeletonClipping_clipEnd(clipper, slot);
        }
    }
    if (clipper != NULL) {
        spSkeletonClipping_clipEnd2(clipper);
    }
    if (releaseData) {
        CFRelease(outVertex);
    }
    SpineMinMaxRect rect = {
        minValue.x,
        minValue.y,
        maxValue.x,
        maxValue.y
    };
    return rect;

}


void spSkeletonClipping_clipTriangles2(spSkeletonClipping *self, float *vertices, int verticesLength,
                                       unsigned short *triangles, int trianglesLength) {
    
    spFloatArray* uvDummy = spFloatArray_create(verticesLength);
    spFloatArray_setSize(uvDummy, verticesLength);
    spSkeletonClipping_clipTriangles(self, vertices, verticesLength, triangles, trianglesLength, uvDummy->items, 2);
    spFloatArray_dispose(uvDummy);
    uvDummy = NULL;
}
