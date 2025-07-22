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

#ifndef SPINE_C_ARRAYS_H
#define SPINE_C_ARRAYS_H

#include <spine-c/arrays.h>
#include <spine-c/atlas_page.h>
#include <stddef.h>
#include <stdbool.h>

SPINE_OPAQUE_TYPE(spine_array_atlas_page)

#ifdef __cplusplus
extern "C" {
#endif





#define SPINE_C_API SPINE_CPP_LITE_EXPORT

SPINE_C_API spine_array_atlas_page spine_array_atlas_page_create(void);

SPINE_C_API spine_array_atlas_page spine_array_atlas_page_create_with_capacity(size_t initialCapacity);
SPINE_C_API void spine_array_atlas_page_dispose(spine_array_atlas_page array);
SPINE_C_API void spine_array_atlas_page_clear(spine_array_atlas_page array);

SPINE_C_API size_t spine_array_atlas_page_get_capacity(spine_array_atlas_page array);

SPINE_C_API size_t spine_array_atlas_page_size(spine_array_atlas_page array);

SPINE_C_API spine_array_atlas_page spine_array_atlas_page_set_size(spine_array_atlas_page array, size_t newSize, spine_atlas_page defaultValue);

SPINE_C_API void spine_array_atlas_page_ensure_capacity(spine_array_atlas_page array, size_t newCapacity);

SPINE_C_API void spine_array_atlas_page_add(spine_array_atlas_page array, spine_atlas_page inValue);

SPINE_C_API void spine_array_atlas_page_add_all(spine_array_atlas_page array, spine_array_atlas_page inValue);

SPINE_C_API void spine_array_atlas_page_clear_and_add_all(spine_array_atlas_page array, spine_array_atlas_page inValue);

SPINE_C_API void spine_array_atlas_page_remove_at(spine_array_atlas_page array, size_t inIndex);

SPINE_C_API bool spine_array_atlas_page_contains(spine_array_atlas_page array, spine_atlas_page inValue);

SPINE_C_API int spine_array_atlas_page_index_of(spine_array_atlas_page array, spine_atlas_page inValue);

SPINE_C_API spine_atlas_page * spine_array_atlas_page_buffer(spine_array_atlas_page array);

#ifdef __cplusplus
}
#endif

#endif /* SPINE_C_ARRAYS_H */
