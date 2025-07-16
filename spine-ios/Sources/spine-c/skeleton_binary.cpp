#include "skeleton_binary.h"
#include <spine/spine.h>

using namespace spine;

spine_skeleton_binary spine_skeleton_binary_create(spine_atlas2 atlas) {
    return (spine_skeleton_binary) new (__FILE__, __LINE__) SkeletonBinary((Atlas *)atlas);
}

// spine_skeleton_binary spine_skeleton_binary_create2(spine_attachment_loader attachmentLoader, bool ownsLoader) {
//     return (spine_skeleton_binary) new (__FILE__, __LINE__) SkeletonBinary((AttachmentLoader *)attachmentLoader, ownsLoader);
// }

void spine_skeleton_binary_dispose(spine_skeleton_binary self) {
    delete (SkeletonBinary*)self;
}

spine_skeleton_data spine_skeleton_binary_read_skeleton_data(spine_skeleton_binary self, const unsigned char * binary, int length) {
    return (spine_skeleton_data)((SkeletonBinary*)self)->readSkeletonData(binary, length);
}

spine_skeleton_data spine_skeleton_binary_read_skeleton_data_file(spine_skeleton_binary self, const char* path) {
    return (spine_skeleton_data)((SkeletonBinary*)self)->readSkeletonDataFile(String(path));
}

void spine_skeleton_binary_set_scale(spine_skeleton_binary self, float scale) {
    ((SkeletonBinary*)self)->setScale(scale);
}

const char* spine_skeleton_binary_get_error(spine_skeleton_binary self) {
    return ((SkeletonBinary*)self)->getError().buffer();
}
