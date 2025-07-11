//
//  Header.h
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//

#ifndef spine_swift_bridge_h
#define spine_swift_bridge_h
#include <spine/spine.h>


namespace spine_support {
using namespace spine;
typedef spine::Vector<float> SpineFloatVector;
typedef spine::Vector<spine::String> SpineStringVector;
typedef spine::Vector<int> SpineIntVector;
typedef spine::Vector<spine::AtlasPage*> SpineAtlasPagePointerVector;
typedef spine::Vector<spine::AtlasRegion *> SpineAtlasRegionPointerVector;


SpineAtlasPagePointerVector &atlas_getPages(spine::Atlas& self);
spine::Vector<spine::AtlasRegion *> &atlas_getRegions(spine::Atlas& self);

spine::TrackEntry *animationState_add(spine::AnimationState& self, size_t trackIndex, spine::Animation *animation, bool loop, float delay);

TrackEntry* animationState_set(AnimationState& self, size_t trackIndex, spine::Animation *animation, bool loop);

spine::TrackEntry *animationState_add(spine::AnimationState& self, size_t trackIndex, const char* name, bool loop, float delay);

TrackEntry* animationState_set(AnimationState& self, size_t trackIndex, const char* name, bool loop);

Vector<BoneData *>& skeletonData_getBones(SkeletonData& self);

Vector<SlotData*> & skeletonData_getSlots(SkeletonData& self);

Vector<Skin*> & skeletonData_getSkins(SkeletonData& self);

Vector<EventData*> & skeletonData_getEvents(SkeletonData& self);

Vector<Animation *> &skeletonData_getAnimations(SkeletonData& self);

Vector<IkConstraintData *> &skeletonData_getIkConstraints(SkeletonData& self);

Vector<TransformConstraintData *> &skeletonData_getTransformConstraints(SkeletonData& self);

Vector<PathConstraintData *> &skeletonData_getPathConstraints(SkeletonData& self);

Vector<PhysicsConstraintData *> &skeletonData_getPhysicsConstraints(SkeletonData& self);


SkeletonData *json_readSkeletonDataFile(SkeletonJson& self, const char* path);

SkeletonData *json_readSkeletonData(SkeletonJson& self, const char *json);

SkeletonData *binary_readSkeletonDataFile(SkeletonBinary& self, const char* path);

SkeletonData *binary_readSkeletonData(SkeletonBinary& self, const unsigned char* __counted_by(length) binary, int length);
Skin * skeleton_getSkin(Skeleton& self);
Skin *SkeletonData_findSkin(SkeletonData& self, const String &skinName);
Animation *SkeletonData_findAnimation(SkeletonData& self,const String &animationName);


String & json_getError(SkeletonJson& self);
String & binary_getError(SkeletonBinary& self);


Atlas* Atlas_load(const char * path);
Atlas* Atlas_load(const char* __counted_by(length) strdata, int length, const char* dir);

const char* peek_String(const String *self);

SkeletonData* animationStateData_getData(AnimationStateData& self);
//void Atlas_dispose(Atlas* atlas);

Skeleton* create_skeleton(SkeletonData& self);
void dispose_skeleton(Skeleton* self);
AnimationState* create_animationState(AnimationStateData& self);
void dispose_animationState(AnimationState* self);

//template <typename T> T &peek_vector(Vector<T>& self, int index);

String& atlasPage_name(AtlasPage& self);
}

#endif /* Header_h */
