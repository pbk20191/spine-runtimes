#include "spine-c/skeleton_json.h"
#include <spine/spine.h>

using namespace spine;

spine_skeleton_json spine_skeleton_json_create(spine_atlas2 atlas) {
    return (spine_skeleton_json) new (__FILE__, __LINE__) SkeletonJson((Atlas *)atlas);
}

// spine_skeleton_json spine_skeleton_json_create2(spine_attachment_loader attachmentLoader, bool ownsLoader) {
//     return (spine_skeleton_json) new (__FILE__, __LINE__) SkeletonJson((AttachmentLoader *)attachmentLoader, ownsLoader);
// }

void spine_skeleton_json_dispose(spine_skeleton_json self) {
    delete (SkeletonJson*)self;
}

spine_skeleton_data spine_skeleton_json_read_skeleton_data_file(spine_skeleton_json self, const char* path) {
    return (spine_skeleton_data)((SkeletonJson*)self)->readSkeletonDataFile(String(path));
}

spine_skeleton_data spine_skeleton_json_read_skeleton_data(spine_skeleton_json self, const char * json) {
    return (spine_skeleton_data)((SkeletonJson*)self)->readSkeletonData(json);
}

void spine_skeleton_json_set_scale(spine_skeleton_json self, float scale) {
    ((SkeletonJson*)self)->setScale(scale);
}

const char* spine_skeleton_json_get_error(spine_skeleton_json self) {
    return ((SkeletonJson*)self)->getError().buffer();
}
