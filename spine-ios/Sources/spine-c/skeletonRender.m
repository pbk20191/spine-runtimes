//
//  skeletonRender.m
//  spine-ios
//
//  Created by 박병관 on 3/17/25.
//

#import <Foundation/Foundation.h>
#include <spine/Skeleton.h>
#include <spine/SkeletonClipping.h>
#include <spine/extension.h>
#include <CoreGraphics/CGGeometry.h>
#include "spine_public.h"
#include "private/SpineCSwiftRenderCommand2Imp.h"

typedef struct {
    spFloatArray* positions;
    spFloatArray* uvs;
    spIntArray* colors;
    spUnsignedShortArray* indices;
    spBlendMode blendMode;
    int textureIndex;
    bool pma;
    CFStringRef pageName;
} SpineRenderCommandBlock;

NS_INLINE SpineRenderCommandBlock sp_render_command_block_create(int numVertices, int numIndices, spBlendMode blendMode, int textureIndex, bool pma, CFStringRef pageName);

NS_INLINE CFMutableArrayRef sp_render_command_block_create_Array();

NS_INLINE spAtlasRegion* spRegionAttachment_getRegion(const spRegionAttachment* self);
NS_INLINE spAtlasRegion* spMeshAttachment_getRegion(const spMeshAttachment* self);
NS_INLINE CFIndex spAtlasRegion_getPageIndex(const spAtlasRegion* self, NSMutableDictionary<NSValue*, NSMutableArray<NSValue*>*>* cache);
NS_INLINE NSString* spAtlasPage_getName(const spAtlasPage* self, NSMutableDictionary<NSValue*, NSString*>* cache);
static SpineCSwiftRenderCommand2Imp* createRenderCommand2(int numVertices, int numIndices, spBlendMode blendMode, int textureIndex, bool pma, NSString* pageName);
static SpineCSwiftRenderCommand2Imp* batchSubCommands(SpineRenderCommandBlock** commands, int first, int last, int numVertices, int numIndices);
static NSMutableArray<SpineCSwiftRenderCommand2Imp*>* batchCommands(CFArrayRef commands);


NSArray<id<SpineCRenderCommand>>* spSkeleton_render(spSkeleton *skeleton, spSkeletonClipping *clipper) {
    spFloatArray *_worldVertices = spFloatArray_create(32);
    NSMutableDictionary* cache = NSMutableDictionary.dictionary;
    NSMutableDictionary* pageNameCache = NSMutableDictionary.dictionary;
    const unsigned short quadIndices[] = {0, 1, 2, 2, 3, 0};
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
        NSString* pageName = @"";
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
            indices->items = quadIndices;
            
            spAtlasRegion *atlasRegion = spRegionAttachment_getRegion(regionAttachment);
            pma = atlasRegion->page->pma;
            texture = spAtlasRegion_getPageIndex(atlasRegion, cache);
            pageName = spAtlasPage_getName(atlasRegion->page, pageNameCache);
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
            pageName = spAtlasPage_getName(atlasRegion->page, pageNameCache);
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
        
        SpineRenderCommandBlock cmd = sp_render_command_block_create(verticesCount, indicesCount, slot->data->blendMode, texture, pma, (__bridge CFStringRef)(pageName));
        // CFArray callback calls malloc interally which we provided
        // see SpineRenderCommandBlock.m
        CFArrayAppendValue(_renderCommands, &cmd);
        spFloatArray_addAllValues(cmd.positions, vertices->items, 0,  verticesCount << 1);
        spFloatArray_addAllValues(cmd.uvs, uvs->items, 0, verticesCount << 1);
        for (int ii = 0; ii < verticesCount; ii++) {
            spIntArray_add(cmd.colors, color);
//            cmd->darkColors[ii] = darkColor;
        }
        spUnsignedShortArray_addAll(cmd.indices, indices);
        spSkeletonClipping_clipEnd(clipper, slot);
    }
    spSkeletonClipping_clipEnd2(clipper);
    NSArray* result = batchCommands( _renderCommands);

    spFloatArray_dispose(_worldVertices);
    CFRelease(_renderCommands);
    return result;
}



// Function to create a new RenderCommandBlock
SpineRenderCommandBlock sp_render_command_block_create(int numVertices, int numIndices, spBlendMode blendMode, int textureIndex, bool pma, CFStringRef pageName) {
    spFloatArray* positions = spFloatArray_create(numVertices << 1);
    spFloatArray* uvs = spFloatArray_create(numVertices << 1);
    spIntArray* colors = spIntArray_create(numVertices);
    spUnsignedShortArray* indices = spUnsignedShortArray_create(numIndices);
    SpineRenderCommandBlock block = {
        positions,
        uvs,
        colors,
        indices,
        blendMode,
        textureIndex,
        pma,
       pageName
    };
    return block;
}


NS_INLINE void releaseRenderCommandBlock2(CFAllocatorRef allocator,const void * valueRef) {
//    NSValue* value = (__bridge NSValue*)valueRef;
    const SpineRenderCommandBlock *block = valueRef;
//    [value getValue:&block size:sizeof(SpineRenderCommandBlock)];
    CFRelease(block->pageName);
    spFloatArray_dispose(block->positions);
    spFloatArray_dispose(block->uvs);
    spIntArray_dispose(block->colors);
    spUnsignedShortArray_dispose(block->indices);
//    CFRelease(valueRef);
    CFAllocatorDeallocate(allocator, (void *) valueRef);
}

NS_INLINE CFTypeRef retainRenderCommandBlock2(CFAllocatorRef allocator, const void * valueRef) {
//    NSValue* value = (__bridge  NSValue*)valueRef;
//    CFRetain(valueRef);
    const SpineRenderCommandBlock *block = valueRef;
    SpineRenderCommandBlock *newValue = CFAllocatorAllocate(allocator, sizeof(SpineRenderCommandBlock), 0);
    memcpy(newValue, block, sizeof(SpineRenderCommandBlock));
//    [value getValue:&block size:sizeof(SpineRenderCommandBlock)];
    CFRetain(block->pageName);
    return newValue;
}




CFMutableArrayRef sp_render_command_block_create_Array() {
    CFArrayCallBacks callbacks = kCFTypeArrayCallBacks;
    callbacks.retain = retainRenderCommandBlock2;
    callbacks.release = releaseRenderCommandBlock2;
    return CFArrayCreateMutable(kCFAllocatorDefault, 0, &callbacks);
}

spAtlasRegion* spRegionAttachment_getRegion(const spRegionAttachment* self) {
    return self->rendererObject;
}

spAtlasRegion* spMeshAttachment_getRegion(const spMeshAttachment* self) {
    return self->rendererObject;
}


CFIndex spAtlasRegion_getPageIndex(const spAtlasRegion* self, NSMutableDictionary<NSValue*, NSMutableArray<NSValue*>*>* cache) {
    NSValue* keyedValue = [NSValue valueWithPointer:self->page->atlas];
    NSMutableArray<NSValue*>* existing = cache[keyedValue];
    if (!existing) {
        existing = NSMutableArray.array;
        cache[keyedValue] = existing;
        spAtlasPage* cursor = self->page->atlas->pages;
        while (cursor != NULL) {
            [existing addObject:[NSValue valueWithPointer:cursor]];
            cursor = cursor->next;
        }
    }
    return [existing indexOfObject:[NSValue valueWithPointer:self->page]];

}

NSString* spAtlasPage_getName(const spAtlasPage* self, NSMutableDictionary<NSValue*, NSString*>* cache) {
    NSValue* keyedValue = [NSValue valueWithPointer:self];
    NSString* existing = cache[keyedValue];
    if (!existing) {
        existing = [NSString stringWithUTF8String:self->name];
        cache[keyedValue] = existing;
    }
    return existing;
}




SpineCSwiftRenderCommand2Imp* createRenderCommand2(int numVertices, int numIndices, spBlendMode blendMode, int textureIndex, bool pma, NSString* pageName) {
    SpineCSwiftRenderCommand2Imp* cmd = SpineCSwiftRenderCommand2Imp.new;
    if (!cmd) {
        NSCAssert(NO, @"Failed to create RenderCommandBlock");
    }
    cmd->_blendMode = blendMode;
    cmd->_textureIndex = textureIndex;
    cmd->_pma = pma;
    cmd->_pageName = pageName;
    cmd->_positions = [NSMutableData dataWithLength:(numVertices << 1) * sizeof(float)];
    cmd->_uvs = [NSMutableData dataWithLength:(numVertices << 1) * sizeof(float)];
    cmd->_colors = [NSMutableData dataWithLength:numVertices * sizeof(int)];
    cmd->_indices = [NSMutableData dataWithLength:numIndices * sizeof(unsigned short)];
    return cmd;
}

// Function to batch a range of RenderCommandBlocks
SpineCSwiftRenderCommand2Imp* batchSubCommands(SpineRenderCommandBlock** commands, int first, int last, int numVertices, int numIndices) {
    if (!commands || first > last) return NULL;

    SpineCSwiftRenderCommand2Imp* batched = createRenderCommand2(numVertices, numIndices, commands[first]->blendMode, commands[first]->textureIndex, commands[first]->pma, (__bridge NSString*)commands[first]->pageName);
    float *positions = batched->_positions.mutableBytes;
    float *uvs = batched->_uvs.mutableBytes;
    int *colors = batched->_colors.mutableBytes;
    unsigned short *indices = batched->_indices.mutableBytes;
    
    int indicesOffset = 0;
    int positionsOffset = 0;
    int uvsOffset = 0;
    int colorsOffset = 0;
    int indicesCount = 0;
    
    for (int i = first; i <= last; i++) {
        SpineRenderCommandBlock* cmd = commands[i];
        memcpy(positions + positionsOffset, cmd->positions->items, sizeof(float) * cmd->positions->size);
        memcpy(uvs + uvsOffset, cmd->uvs->items, sizeof(float) * cmd->uvs->size);
        memcpy(colors + colorsOffset, cmd->colors->items, sizeof(int) * cmd->colors->size);

        for (int j = 0; j < cmd->indices->size; j++) {
            indices[indicesCount + j] = cmd->indices->items[j] + indicesOffset;
        }
        // 크기 업데이트
        positionsOffset += cmd->positions->size;
        uvsOffset += cmd->uvs->size;
        colorsOffset += cmd->colors->size;
        indicesCount += cmd->indices->size;
        indicesOffset += cmd->positions->size / 2;
    }
    return batched;
}

// Function to batch all RenderCommandBlocks
NSMutableArray<SpineCSwiftRenderCommand2Imp*>* batchCommands(CFArrayRef commands) {
    NSMutableArray<SpineCSwiftRenderCommand2Imp*>* buffer = NSMutableArray.array;
    const NSInteger commandCount = CFArrayGetCount(commands);
    if (!commands || commandCount == 0) return buffer;
    
    SpineRenderCommandBlock** commandBuffers = MALLOC(SpineRenderCommandBlock*, commandCount);
//
    CFArrayGetValues(commands, CFRangeMake(0, commandCount), (const void**)commandBuffers);
    SpineCSwiftRenderCommand2Imp* last = NULL;
    
    int startIndex = 0;
    int i = 1;
    int numVertices = commandBuffers[0]->positions->size / 2;
    int numIndices = commandBuffers[0]->indices->size;

    while (i <= commandCount) {
        SpineRenderCommandBlock* cmd = (i < commandCount) ? commandBuffers[i] : NULL;

        if (cmd && cmd->uvs->size == 0 && cmd->indices->size == 0) {
            i++;
            continue;
        }
        
        if (cmd != NULL && cmd->blendMode == commandBuffers[startIndex]->blendMode &&
            cmd->textureIndex == commandBuffers[startIndex]->textureIndex
            && numIndices + cmd->indices->size < 0xFFFF
            ) {
            numVertices += cmd->positions->size / 2;
            numIndices += cmd->indices->size;
        } else {
            SpineCSwiftRenderCommand2Imp* batched = batchSubCommands(commandBuffers, startIndex, i - 1, numVertices, numIndices);
            if (!last) {
                [buffer addObject:batched];
                last = batched;
            } else {
                [buffer addObject:batched];
                last = batched;
            }
            if (i == commandCount) break;

            startIndex = i;
            numVertices = commandBuffers[i]->positions->size / 2;
            numIndices = commandBuffers[i]->indices->size;
        }
        i++;
    }

    FREE(commandBuffers);
    return buffer;
}
