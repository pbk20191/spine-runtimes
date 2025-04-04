//
//  skeletonRender.m
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

#include <spine/spine.h>
#include <spine/extension.h>
#include "spine_public.h"


typedef struct {
    // owned by the external object pool
    CFMutableDataRef head;
    CFOptionFlags size;
} SpineCommandArray;

CF_INLINE CFMutableArrayRef sp_render_command_block_create_Array();
CF_INLINE SpineRenderBatchCommand sp_render_command_block_create(CFIndex numVertices, CFIndex numIndices, spBlendMode blendMode, CFIndex textureIndex, bool pma, const char* pageName, CFMutableArrayRef blockPool);

CF_INLINE spAtlasRegion* spRegionAttachment_getRegion(const spRegionAttachment* self);
CF_INLINE spAtlasRegion* spMeshAttachment_getRegion(const spMeshAttachment* self);
CF_INLINE CFIndex spAtlasRegion_getPageIndex(const spAtlasRegion* self, CFMutableDictionaryRef cache);

CF_INLINE bool batchSubCommands(SpineRenderBatchCommand** commands, CFIndex first, CFIndex last, CFIndex numVertices, CFIndex numIndices, CFMutableArrayRef batchPool, SpineRenderBatchCommand* outptr);

CF_INLINE SpineCommandArray batchCommands(CFArrayRef commands, CFMutableArrayRef batchPool);


void spSkeleton_render(spSkeleton *skeleton, spSkeletonClipping *clipper, SpineRenderBatchCommandHandler function, void * _Nullable context) {

    spFloatArray *_worldVertices = spFloatArray_create(32);
    
    CFMutableDictionaryRef cache = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableArrayRef blockPool = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    const unsigned short quadIndices[] = {0, 1, 2, 2, 3, 0};
    float region_vertices[] = {0,0,0,0,0,0,0,0};
    const char emptyCString[] = "";
    spFloatArray uvsHolder = {0,0,0};
    spUnsignedShortArray indicesHolder = {0,0,0};
    CFMutableArrayRef _renderCommands = sp_render_command_block_create_Array();
    for (unsigned i = 0; i < skeleton->slotsCount; ++i) {
        spSlot* slot = skeleton->drawOrder[i];
        spAttachment *attachment = slot->attachment;
        if (!attachment) {
            spSkeletonClipping_clipEnd(clipper, slot);
            continue;
        }
        //
        // Early out if the slot color is 0 or the bone is not active
        if ((slot->color.a == 0 || !slot->bone->active) && attachment->type != SP_ATTACHMENT_CLIPPING) {
            spSkeletonClipping_clipEnd(clipper, slot);
            continue;
        }
        
        spFloatArray *vertices = _worldVertices;
        spFloatArray *uvs = &uvsHolder;
        spUnsignedShortArray *indices = &indicesHolder;
        spColor attachmentColor;

        void *texture;
        bool pma = false;
        char* pageName = (char*) emptyCString;
        if (attachment->type == SP_ATTACHMENT_REGION) {
            spRegionAttachment *regionAttachment = SUB_CAST(spRegionAttachment, attachment);
            attachmentColor = regionAttachment->color;
            
            // Early out if the slot color is 0
            if (attachmentColor.a == 0) {
                spSkeletonClipping_clipEnd(clipper, slot);
                continue;
            }
            
            spFloatArray_setSize(vertices, 8);
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
            spAtlasRegion *atlasRegion = spRegionAttachment_getRegion(regionAttachment);
            pma = atlasRegion->page->pma;
            texture = spAtlasRegion_getPageIndex(atlasRegion, cache);
            pageName = atlasRegion->page->name;
        } else if (attachment->type == SP_ATTACHMENT_MESH) {
            spMeshAttachment *mesh = SUB_CAST(spMeshAttachment, attachment);
            
            attachmentColor = mesh->color;
            
            // Early out if the slot color is 0
            if (attachmentColor.a == 0) {
                spSkeletonClipping_clipEnd(clipper, slot);
                continue;
            }
            //
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
            spAtlasRegion *atlasRegion = spMeshAttachment_getRegion(mesh);
            pma = atlasRegion->page->pma;
            texture = spAtlasRegion_getPageIndex(atlasRegion, cache);
            pageName = atlasRegion->page->name;
        } else if (attachment->type == SP_ATTACHMENT_CLIPPING) {
            spClippingAttachment *clip = SUB_CAST(spClippingAttachment, attachment);
            spSkeletonClipping_clipStart(clipper, slot, clip);
            continue;
        } else {
            continue;
        }
        
        float f_a = skeleton->color.a * slot->color.a * attachmentColor.a;
        uint32_t a = (uint8_t)(f_a * 255);
        uint32_t color;
        float f_r = skeleton->color.r * slot->color.r * attachmentColor.r;
        float f_g = skeleton->color.g * slot->color.g * attachmentColor.g;
        float f_b = skeleton->color.b * slot->color.b * attachmentColor.b;
        if (pma) {
            uint32_t r = (uint8_t)(f_r * f_a * 255);
            uint32_t g = (uint8_t)(f_g * f_a * 255);
            uint32_t b = (uint8_t)(f_b * f_a * 255);
            color = (a << 24) | (r << 16) | (g << 8) | b;
        } else {
            uint32_t r = (uint8_t)(f_r * 255);
            uint32_t g = (uint8_t)(f_g * 255);
            uint32_t b = (uint8_t)(f_b * 255);
            color = (a << 24) | (r << 16) | (g << 8) | b;
        }
        spRenderColor colorData;
        colorData.color = color;
        colorData.darkColor = 0xff000000;
        if (slot->darkColor) {
            colorData.hasDark = true;
            spColor slotDarkColor = *slot->darkColor;
            uint32_t dr = (uint8_t)(slotDarkColor.r * (pma ? f_a : 1) * 255);
            uint32_t dg = (uint8_t)(slotDarkColor.g * (pma ? f_a : 1) * 255);
            uint32_t db = (uint8_t)(slotDarkColor.b * (pma ? f_a : 1) * 255);
            uint32_t da = (uint8_t)( (pma ? 1 : 0) * 255);
            
            uint32_t darkColor = (da << 24) | (dr << 16) | (dg << 8) | db;
            colorData.darkColor = darkColor;
        } else {
            colorData.darkColor = 0xff000000;
            colorData.hasDark = false;
        }
        
        if (spSkeletonClipping_isClipping(clipper)) {
            spSkeletonClipping_clipTriangles(clipper, vertices->items, vertices->size >> 1, indices->items, indices->size, uvs->items, 2);
            vertices = clipper->clippedVertices;

            uvs = clipper->clippedUVs;
            indices = clipper->clippedTriangles;
        }
        const int verticesCount = vertices->size >> 1;
        SpineRenderBatchCommand cmd = sp_render_command_block_create(verticesCount, indices->size, slot->data->blendMode, texture, pma, pageName, blockPool);
        // CFArray callback calls malloc interally which we provided
        CFArrayAppendValue(_renderCommands, &cmd);
        memcpy(cmd.positions, vertices->items, (vertices->size) * sizeof(float));
        memcpy(cmd.uvs, uvs->items, (uvs->size) * sizeof(float));
//        assert(vertices->size == verticesCount << 1);
        for (int ii = 0; ii < verticesCount; ii++) {
            cmd.colors[ii] = colorData;
        }
        memcpy(cmd.indices, indices->items, indices->size * (sizeof(unsigned short)));
        spSkeletonClipping_clipEnd(clipper, slot);
    }
    spSkeletonClipping_clipEnd2(clipper);
    CFMutableArrayRef batchPool = CFArrayCreateMutable(kCFAllocatorMalloc, 0, &kCFTypeArrayCallBacks);
    SpineCommandArray result = batchCommands( _renderCommands, batchPool);
    do {
        CFRelease(cache);
        cache = NULL;
        // release block backed memory
        CFRelease(blockPool);
        blockPool = NULL;
        CFRelease(_renderCommands);
        _renderCommands = NULL;
    } while(0);
    spFloatArray_dispose(_worldVertices);
    _worldVertices = NULL;
    const CFOptionFlags batchCount = result.size;
    const SpineRenderBatchCommand* head = result.head ? CFDataGetBytePtr(result.head) : NULL;
    function(head, batchCount, context);
    CFRelease(batchPool);
}



// Function to create a new RenderCommandBlock
CF_INLINE SpineRenderBatchCommand sp_render_command_block_create(CFIndex numVertices, CFIndex numIndices, spBlendMode blendMode, CFIndex textureIndex, bool pma, const char* pageName, CFMutableArrayRef blockPool) {
#define SPBufferCreate(name, type, size) CFMutableDataRef name = CFDataCreateMutable(kCFAllocatorDefault, sizeof(type)*size); \
    CFDataSetLength(name, sizeof(type)*size); \
    CFArrayAppendValue(blockPool, name); \
    CFRelease(name);
    
    SpineRenderBatchCommand block;
    block.pageIndex = textureIndex;
    block.colorCount = numVertices;
    block.uvCount = block.positionCount = numVertices << 1;
    block.indexCount = numIndices;
    block.pageName = pageName;
    block.pma = pma;
    block.blendMode = blendMode;
    do {
        SPBufferCreate(positionData, float, block.positionCount)
        block.positions = (float*) CFDataGetMutableBytePtr(positionData);
    } while(0);
    do {
        SPBufferCreate(uvData, float,  block.uvCount)
        block.uvs = (float*) CFDataGetMutableBytePtr(uvData);
    } while(0);
    do {
        SPBufferCreate(colorData, spRenderColor, block.colorCount)
        block.colors = (spRenderColor*) CFDataGetMutableBytePtr(colorData);
    } while(0);
    do {
        SPBufferCreate(indicesData, unsigned short, block.indexCount);
        block.indices = (unsigned short*) CFDataGetMutableBytePtr(indicesData);
    } while(0);

    return block;
}



CF_INLINE spAtlasRegion* spRegionAttachment_getRegion(const spRegionAttachment* self) {
    return self->rendererObject;
}

CF_INLINE spAtlasRegion* spMeshAttachment_getRegion(const spMeshAttachment* self) {
    return self->rendererObject;
}


CF_INLINE CFIndex spAtlasRegion_getPageIndex(const spAtlasRegion* self, CFMutableDictionaryRef cache) {
    uintptr_t selfPtr = (uintptr_t)self->page->atlas;
    CFTypeRef keyedValue =  CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &selfPtr);
    
    CFMutableArrayRef existing = (CFMutableArrayRef) CFDictionaryGetValue(cache, keyedValue);
//    CFDictionary

    if (!existing) {
        existing = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(cache, keyedValue, existing);
        CFRelease(existing);
        spAtlasPage* cursor = self->page->atlas->pages;
        while (cursor != NULL) {
            CFArrayAppendValue(existing, cursor);
            cursor = cursor->next;
        }
    }
    CFRelease(keyedValue);
    
    return CFArrayGetFirstIndexOfValue(existing, CFRangeMake(0, CFArrayGetCount(existing)), self->page);

}

// Function to batch a range of RenderCommandBlocks
CF_INLINE bool batchSubCommands(SpineRenderBatchCommand** commands, CFIndex first, CFIndex last, CFIndex numVertices, CFIndex numIndices, CFMutableArrayRef batchPool, SpineRenderBatchCommand* outptr) {
    if (!commands || first > last) {
        return false;
    }

    
    SpineRenderBatchCommand batched = sp_render_command_block_create(numVertices, numIndices, commands[first]->blendMode, commands[first]->pageIndex,  commands[first]->pma, commands[first]->pageName, batchPool);
    float *positions = batched.positions;
    float *uvs = batched.uvs;
    spRenderColor *colors = batched.colors;
    unsigned short *indices = batched.indices;
    
    CFIndex positionsOffset = 0;
    CFIndex indicesCount = 0;
    
    for (CFIndex i = first; i <= last; i++) {
        SpineRenderBatchCommand* cmd = commands[i];
        CFIndex vertexCount = cmd->positionCount / 2;

        memcpy(positions + positionsOffset, cmd->positions, sizeof(float) * cmd->positionCount);
        memcpy(uvs + positionsOffset, cmd->uvs, sizeof(float) * cmd->uvCount);
        memcpy(colors + positionsOffset / 2, cmd->colors, sizeof(spRenderColor) * cmd->colorCount);
        for (CFIndex j = 0; j < cmd->indexCount; j++) {
            indices[indicesCount + j] = cmd->indices[j] + positionsOffset / 2;
        }

        positionsOffset += cmd->positionCount;
        indicesCount += cmd->indexCount;
    }
    *outptr = batched;
    return true;
}


// Function to batch all RenderCommandBlocks
CF_INLINE SpineCommandArray batchCommands(CFArrayRef commands, CFMutableArrayRef batchPool) {
    const CFIndex commandCount = CFArrayGetCount(commands);
    SpineCommandArray arrayRef = {};
    if (!commands || commandCount == 0) {
        return arrayRef;
    }
    arrayRef.head = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CFArrayAppendValue(batchPool, arrayRef.head);
    CFRelease(arrayRef.head);
    arrayRef.size = 0;
    SpineRenderBatchCommand** commandBuffers = MALLOC(SpineRenderBatchCommand*, commandCount);
//
    CFArrayGetValues(commands, CFRangeMake(0, commandCount), (const void**)commandBuffers);
    
    CFIndex startIndex = 0;
    CFIndex i = 1;
    CFIndex numVertices = commandBuffers[0]->positionCount / 2;
    CFIndex numIndices = commandBuffers[0]->indexCount;

    while (i <= commandCount) {
        SpineRenderBatchCommand* cmd = (i < commandCount) ? commandBuffers[i] : NULL;

        if (cmd && cmd->uvCount == 0 && cmd->indexCount == 0) {
            i++;
            continue;
        }
        
        if (cmd != NULL && cmd->blendMode == commandBuffers[startIndex]->blendMode &&
            cmd->pageIndex == commandBuffers[startIndex]->pageIndex
            && numIndices + cmd->indexCount < 0xFFFF
            ) {
            numVertices += cmd->positionCount / 2;
            numIndices += cmd->indexCount;
        } else {
            SpineRenderBatchCommand batched;
            const Boolean success = batchSubCommands(commandBuffers, startIndex, i - 1, numVertices, numIndices, batchPool, &batched);
            if (success) {
                CFDataAppendBytes(arrayRef.head, (void*)&batched, sizeof(SpineRenderBatchCommand));
                arrayRef.size += 1;
            }
            if (i == commandCount) break;

            startIndex = i;
            numVertices = commandBuffers[i]->positionCount / 2;
            numIndices = commandBuffers[i]->indexCount;
        }
        i++;
    }

    FREE(commandBuffers);
    return arrayRef;
}

//CF_In
CF_INLINE void sp_rener_command_cfarray_release(CFAllocatorRef allocator, const void* item) {
    SpineRenderBatchCommand* cmd = (SpineRenderBatchCommand*) item;
    CFAllocatorDeallocate(allocator, cmd);
}

CF_INLINE const void* sp_render_command_cfarray_retain(CFAllocatorRef allocator, const void* input) {
    SpineRenderBatchCommand* cmd = (SpineRenderBatchCommand*) input;

    SpineRenderBatchCommand* new = CFAllocatorAllocate(allocator, sizeof(SpineRenderBatchCommand), 0);
    *new = *cmd;
    return new;
}

CF_INLINE CFMutableArrayRef sp_render_command_block_create_Array() {
    CFArrayCallBacks cb = {};
    cb.release = sp_rener_command_cfarray_release;
    cb.retain = sp_render_command_cfarray_retain;
    return CFArrayCreateMutable(kCFAllocatorDefault, 0, &cb);
}
