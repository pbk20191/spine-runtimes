//
//  skeletonRender.m
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

#include <spine/spine.h>
#include <spine/extension.h>
#include "spine_public.h"

void spSkeleton_render(spSkeleton *skeleton, spSkeletonClipping *clipper, SpineRenderBatchCommandHandler function, void * _Nullable context) {
    spFloatArray *_worldVertices = spFloatArray_create(32);
    const unsigned short quadIndices[6] = {0, 1, 2, 2, 3, 0};
    float region_vertices_item[8] = {0,0,0,0,0,0,0,0};
    const spFloatArray region_vertices = {
        .items = region_vertices_item,
        .size = 8,
        .capacity = 8
    };

    for (unsigned i = 0; i < skeleton->slotsCount; ++i) {
        spSlot* slot = skeleton->drawOrder[i];
        spAttachment *attachment = slot->attachment;
        if (!attachment) {
            if (clipper) {
                spSkeletonClipping_clipEnd(clipper, slot);
            }
            continue;
        }
        //
        // Early out if the slot color is 0 or the bone is not active
        if ((slot->color.a == 0 || !slot->bone->active) && attachment->type != SP_ATTACHMENT_CLIPPING) {
            if (clipper) {
                spSkeletonClipping_clipEnd(clipper, slot);
            }
            continue;
        }
        spFloatArray uvsHolder = {
            .items = NULL,
            .size = 0,
            .capacity = 0,
        };
        spUnsignedShortArray indicesHolder = {
            .items = NULL,
            .size = 0,
            .capacity = 0,
        };
        
        spFloatArray *vertices = _worldVertices;
        spFloatArray *uvs = &uvsHolder;
        spUnsignedShortArray *indices = &indicesHolder;
        
        //@begin
        spColor attachmentColor;
        void *texture = NULL;
        //@end
        
        if (attachment->type == SP_ATTACHMENT_REGION) {
            spRegionAttachment *regionAttachment = SUB_CAST(spRegionAttachment, attachment);
            attachmentColor = regionAttachment->color;
            
            // Early out if the slot color is 0
            if (attachmentColor.a == 0) {
                if (clipper) {
                    spSkeletonClipping_clipEnd(clipper, slot);
                }
                continue;
            }
            
            if (vertices != &region_vertices) {
                vertices = (spFloatArray *)&region_vertices;
            }
            spRegionAttachment_computeWorldVertices(regionAttachment, slot, vertices->items, 0, 2);
            *uvs = (spFloatArray){
                .items = regionAttachment->uvs,
                .size = 8,
                .capacity = 8
            };
            *indices = (spUnsignedShortArray){
                .items = (unsigned short*) quadIndices,
                .size = 6,
                .capacity = 6
            };
            //@begin
            texture = regionAttachment->rendererObject;
            //@end
        } else if (attachment->type == SP_ATTACHMENT_MESH) {
            spMeshAttachment *mesh = SUB_CAST(spMeshAttachment, attachment);
            
            attachmentColor = mesh->color;
            
            // Early out if the slot color is 0
            if (attachmentColor.a == 0) {
                if (clipper) {
                    spSkeletonClipping_clipEnd(clipper, slot);
                }
                continue;
            }
            if (vertices != _worldVertices) {
                vertices = _worldVertices;
            }
            spFloatArray_setSize(vertices,mesh->super.worldVerticesLength);
            spVertexAttachment_computeWorldVertices(&mesh->super, slot, 0, mesh->super.worldVerticesLength, vertices->items, 0, 2);
            *uvs = (spFloatArray){
                .items = mesh->uvs,
                .size = mesh->super.worldVerticesLength,
                .capacity = mesh->super.worldVerticesLength,
            };
            *indices = (spUnsignedShortArray) {
              .items = mesh->triangles,
              .size = mesh->trianglesCount,
              .capacity = mesh->trianglesCount,
            };
            //@begin
            texture = mesh->rendererObject;
            //@end
        } else if (attachment->type == SP_ATTACHMENT_CLIPPING && clipper) {
            spClippingAttachment *clip = SUB_CAST(spClippingAttachment, attachment);
            spSkeletonClipping_clipStart(clipper, slot, clip);
            continue;
        } else {
            continue;
        }
        if (clipper && spSkeletonClipping_isClipping(clipper)) {
            spSkeletonClipping_clipTriangles(clipper, vertices->items, vertices->size >> 1, indices->items, indices->size, uvs->items, 2);
            vertices = clipper->clippedVertices;
            uvs = clipper->clippedUVs;
            indices = clipper->clippedTriangles;
        }
        SpineRenderCommandBlock cmd = {
            .positions = vertices->items,
            .positionCount = vertices->size,
            .uvs = uvs->items,
            .uvCount = uvs->size,
            .indices = indices->items,
            .indexCount = indices->size,
            .blendMode = slot->data->blendMode,
            .renderer = texture,
            .slot = slot,
        };
        function(&cmd, context);
        //@end
        if (clipper) {
            spSkeletonClipping_clipEnd(clipper, slot);
        }
    }
    if (clipper) {
        spSkeletonClipping_clipEnd2(clipper);
    }
    spFloatArray_dispose(_worldVertices);
}
