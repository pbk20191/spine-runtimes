#include "spine-c/atlas.h"
#include <spine/spine.h>

using namespace spine;


void spine_atlas2_flip_v(spine_atlas self) {
    ((Atlas*)self)->flipV();
}

spine_array_atlas_page spine_atlas2_get_pages(spine_atlas2 self) {
    return (spine_array_atlas_page)&((Atlas*)self)->getPages();
}

// spine_atlas2 spine_atlas_get_native(spine_atlas self) {
//     if (!self) {
//         return nil;
//     }
//     auto imp = reinterpret_cast<_spine_atlas*>(self)->atlas;
//     return reinterpret_cast<spine_atlas2>(imp);
// }

void spine_atlas2_dispose(spine_atlas2 self) {
    if (!self) {
        return;
    }
    auto imp = reinterpret_cast<spine::Atlas*>(self);
    delete imp;
}
