/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated April 5, 2025. Replaces all prior versions.
 *
 * Copyright (c) 2013-2025, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#include "arrays.h"
#include <spine/spine.h>
#include <spine/Vector.h>

using namespace spine;
#define Array Vector
spine_array_atlas_page spine_array_atlas_page_create(void) {
    return (spine_array_atlas_page) new (__FILE__, __LINE__) Array<AtlasPage *>();
}

spine_array_atlas_page spine_array_atlas_page_create_with_capacity(size_t initialCapacity) {
    spine::Vector<AtlasPage*>();
    auto t = new (__FILE__, __LINE__) Array<AtlasPage *>();
    t->ensureCapacity(initialCapacity);
    return reinterpret_cast<spine_array_atlas_page>(t);
}
void spine_array_atlas_page_dispose(spine_array_atlas_page array) {
    delete (Array<AtlasPage *>*)array;
}
void spine_array_atlas_page_clear(spine_array_atlas_page array) {
    ((Array<AtlasPage *>*)array)->clear();
}

size_t spine_array_atlas_page_get_capacity(spine_array_atlas_page array) {
    return ((Array<AtlasPage *>*)array)->getCapacity();
}

size_t spine_array_atlas_page_size(spine_array_atlas_page array) {
    return ((Array<AtlasPage *>*)array)->size();
}

spine_array_atlas_page spine_array_atlas_page_set_size(spine_array_atlas_page array, size_t newSize, spine_atlas_page defaultValue) {
    auto t = reinterpret_cast<Vector<AtlasPage*>*>(array);
    auto k = reinterpret_cast<AtlasPage*>(defaultValue);
    t->setSize(newSize, k);
    return reinterpret_cast<spine_array_atlas_page>(t);
//    return (spine_array_atlas_page)&((Array<AtlasPage *>*)array)->setSize(newSize, (AtlasPage *)defaultValue);
}

void spine_array_atlas_page_ensure_capacity(spine_array_atlas_page array, size_t newCapacity) {
    ((Array<AtlasPage *>*)array)->ensureCapacity(newCapacity);
}

void spine_array_atlas_page_add(spine_array_atlas_page array, spine_atlas_page inValue) {
    ((Array<AtlasPage *>*)array)->add((AtlasPage *)inValue);
}

void spine_array_atlas_page_add_all(spine_array_atlas_page array, spine_array_atlas_page inValue) {
    ((Array<AtlasPage *>*)array)->addAll(*((const Array<AtlasPage *>*)inValue));
}

void spine_array_atlas_page_clear_and_add_all(spine_array_atlas_page array, spine_array_atlas_page inValue) {
    ((Array<AtlasPage *>*)array)->clearAndAddAll(*((const Array<AtlasPage *>*)inValue));
}

void spine_array_atlas_page_remove_at(spine_array_atlas_page array, size_t inIndex) {
    ((Array<AtlasPage *>*)array)->removeAt(inIndex);
}

bool spine_array_atlas_page_contains(spine_array_atlas_page array, spine_atlas_page inValue) {
    return ((Array<AtlasPage *>*)array)->contains((AtlasPage *)inValue);
}

int spine_array_atlas_page_index_of(spine_array_atlas_page array, spine_atlas_page inValue) {
    return ((Array<AtlasPage *>*)array)->indexOf((AtlasPage *)inValue);
}

spine_atlas_page * spine_array_atlas_page_buffer(spine_array_atlas_page array) {
    return (spine_atlas_page *)((Array<AtlasPage *>*)array)->buffer();
}
