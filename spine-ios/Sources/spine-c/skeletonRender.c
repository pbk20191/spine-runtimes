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
        
        spFloatArray *worldVertices = _worldVertices;
        spFloatArray *vertices = worldVertices;
        int32_t verticesCount;
        spFloatArray *uvs = &uvsHolder;
        spUnsignedShortArray *indices = &indicesHolder;
        int32_t indicesCount;
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
            spFloatArray_setSize(worldVertices, 8);
            spRegionAttachment_computeWorldVertices(regionAttachment, slot, worldVertices->items, 0, 2);
            verticesCount = 4;
//            uvs = regionAttachment->uvs;
            uvs->items = regionAttachment->uvs;
            uvs->capacity = uvs->size = 8;
            indices->capacity = indices->size = indicesCount = 6;
            indices->items = (unsigned short*) quadIndices;
            
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
            spFloatArray_setSize(worldVertices,mesh->super.worldVerticesLength);
            spVertexAttachment_computeWorldVertices(&mesh->super, slot, 0, mesh->super.worldVerticesLength, worldVertices->items, 0, 2);
            verticesCount = (int32_t) (mesh->super.worldVerticesLength >> 1);
            uvs->items = mesh->uvs;
            uvs->size = uvs->capacity = mesh->trianglesCount;
            indices->items = mesh->triangles;
            indicesCount = indices->size = indices->capacity = mesh->trianglesCount;
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
        
        uint8_t r = (skeleton->color.r * slot->color.r * attachmentColor.r * 255);
        uint8_t g = (skeleton->color.g * slot->color.g * attachmentColor.g * 255);
        uint8_t b = (skeleton->color.b * slot->color.b * attachmentColor.b * 255);
        uint8_t a = (skeleton->color.a * slot->color.a * attachmentColor.a * 255);
        uint32_t color = (a << 24) | (r << 16) | (g << 8) | b;
        uint32_t darkColor = 0xff000000;
        
        if (slot->darkColor) {
            spColor slotDarkColor = *slot->darkColor;
            uint8_t dr = (slotDarkColor.r * 255);
            uint8_t dg = (slotDarkColor.g * 255);
            uint8_t db = (slotDarkColor.b * 255);
            darkColor = 0xff000000 | (dr << 16) | (dg << 8) | db;
        }
        
        if (spSkeletonClipping_isClipping(clipper)) {
            spSkeletonClipping_clipTriangles(clipper, worldVertices->items, verticesCount, indices->items, indicesCount, uvs->items, 2);
            vertices = clipper->clippedVertices;
            verticesCount = clipper->clippedVertices->size >> 1;
            uvs = clipper->clippedUVs;
            indices = clipper->clippedTriangles;
            indicesCount = clipper->clippedTriangles->size;
        }
        SpineRenderBatchCommand cmd = sp_render_command_block_create(verticesCount, indicesCount, slot->data->blendMode, texture, pma, pageName, blockPool);
        // CFArray callback calls malloc interally which we provided
        CFArrayAppendValue(_renderCommands, &cmd);
        memcpy(cmd.positions, vertices->items, (verticesCount << 1) * sizeof(float));
        memcpy(cmd.uvs, uvs->items, (verticesCount << 1) * sizeof(float));
        for (int ii = 0; ii < verticesCount; ii++) {
            cmd.colors[ii] = color;
//            cmd->darkColors[ii] = darkColor;
        }
        memcpy(cmd.indices, indices->items, indices->size * (sizeof(unsigned short)));
        spSkeletonClipping_clipEnd(clipper, slot);
    }
    spSkeletonClipping_clipEnd2(clipper);
    CFMutableArrayRef batchPool = CFArrayCreateMutable(kCFAllocatorMalloc, 0, &kCFTypeArrayCallBacks);
    SpineCommandArray result = batchCommands( _renderCommands, batchPool);
    CFRelease(cache);
    // release block backed memory
    CFRelease(blockPool);
    CFRelease(_renderCommands);
    spFloatArray_dispose(_worldVertices);
    blockPool = nil;
    _renderCommands = nil;
    _worldVertices = nil;
    
    const CFOptionFlags batchCount = result.size;
    const SpineRenderBatchCommand* head = result.head ? CFDataGetBytePtr(result.head) : NULL;
    function(head, batchCount, context);
    CFRelease(batchPool);
    if (result.head) {
        CFRelease(result.head);
    }
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
        SPBufferCreate(colorData, int, block.colorCount)
        block.colors = (int*) CFDataGetMutableBytePtr(colorData);
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
        existing = CFArrayCreateMutable(kCFAllocatorDefault, 0, nil);
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
    int *colors = batched.colors;
    unsigned short *indices = batched.indices;
    
    CFIndex indicesOffset = 0;
    CFIndex positionsOffset = 0;
    CFIndex uvsOffset = 0;
    CFIndex colorsOffset = 0;
    CFIndex indicesCount = 0;
    
    for (CFIndex i = first; i <= last; i++) {
        SpineRenderBatchCommand* cmd = commands[i];
        memcpy(positions + positionsOffset, cmd->positions, sizeof(float) * cmd->positionCount);
        memcpy(uvs + uvsOffset, cmd->uvs, sizeof(float) * cmd->uvCount);
        memcpy(colors + colorsOffset, cmd->colors, sizeof(int) * cmd->colorCount);

        for (CFIndex j = 0; j < cmd->indexCount; j++) {
            indices[indicesCount + j] = cmd->indices[j] + indicesOffset;
        }
        // 크기 업데이트
        positionsOffset += cmd->positionCount;
        uvsOffset += cmd->uvCount;
        colorsOffset += cmd->colorCount;
        indicesCount += cmd->indexCount;
        indicesOffset += cmd->positionCount / 2;
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
