//
//  spine_swift_bridge.m
//  spine-ios
//
//  Created by 박병관 on 7/11/25.
//

#include <spine/spine.h>
#include <CoreFoundation/CoreFoundation.h>
#include "spine_swift_bridge.hpp"
#include "spine_public.hpp"

using namespace spine;

namespace spine_support {
SpineAtlasPagePointerVector & atlas_getPages(spine::Atlas& self) {
    return self.getPages();
}
SpineAtlasRegionPointerVector &atlas_getRegions(spine::Atlas& self) {
    return self.getRegions();
}
//7777777777777777777777777777777u777777777877778777

spine::TrackEntry *animationState_add(spine::AnimationState& self, size_t trackIndex, spine::Animation *animation, bool loop, float delay){
    return self.addAnimation(trackIndex, animation, loop, delay);
}


TrackEntry* animationState_set(AnimationState& self, size_t trackIndex, spine::Animation *animation, bool loop) {
    return self.setAnimation(trackIndex, animation, loop);
}

spine::TrackEntry *animationState_add(spine::AnimationState& self, size_t trackIndex, const char* name, bool loop, float delay) {
    return self.addAnimation(trackIndex, String(name), loop, delay);
}

TrackEntry* animationState_set(AnimationState& self, size_t trackIndex, const char* name, bool loop) {
    
    return self.setAnimation(trackIndex, String(name), loop);
}


Vector<BoneData *>& skeletonData_getBones(SkeletonData& self) {
    return self.getBones();
}

Vector<SlotData*> & skeletonData_getSlots(SkeletonData& self) {
    return self.getSlots();
}

Vector<Skin*> & skeletonData_getSkins(SkeletonData& self) {
    return self.getSkins();
}

Vector<EventData*> & skeletonData_getEvents(SkeletonData& self) {
    return self.getEvents();
}

Vector<Animation *> &skeletonData_getAnimations(SkeletonData& self) {
    return self.getAnimations();
}

Vector<IkConstraintData *> &skeletonData_getIkConstraints(SkeletonData& self) {
    return self.getIkConstraints();
}

Vector<TransformConstraintData *> &skeletonData_getTransformConstraints(SkeletonData& self) {
    return self.getTransformConstraints();
}

Vector<PathConstraintData *> &skeletonData_getPathConstraints(SkeletonData& self) {
    return self.getPathConstraints();
}

Vector<PhysicsConstraintData *> &skeletonData_getPhysicsConstraints(SkeletonData& self) {
    return self.getPhysicsConstraints();
}

SkeletonData *json_readSkeletonDataFile(SkeletonJson& self, const char* path) {
    auto str = String(path, true, false);
    auto value = self.readSkeletonDataFile(str);
    str.unown();
    return value;
}

SkeletonData *json_readSkeletonData(SkeletonJson& self, const char *json) {
    return self.readSkeletonData(json);
}

SkeletonData *binary_readSkeletonDataFile(SkeletonBinary& self, const char* path) {
    auto str = String(path, true, false);
    auto value = self.readSkeletonDataFile(str);
    str.unown();
    return value;
}

SkeletonData *binary_readSkeletonData(SkeletonBinary& self, const unsigned char* __counted_by(length) binary, int length) {
    return self.readSkeletonData(binary, length);
}

Skin * skeleton_getSkin(Skeleton& self) {
    return self.getSkin();
}

Skin *SkeletonData_findSkin(SkeletonData& self,const String &skinName) {
    return self.findSkin(skinName);
}
Animation *SkeletonData_findAnimation(SkeletonData& self,const String &animationName) {
    return self.findAnimation(animationName);
}

String & json_getError(SkeletonJson& self) {
    return self.getError();
}
String & binary_getError(SkeletonBinary& self) {
    return self.getError();
}


Atlas* Atlas_load(const char * path) {
    auto str = String(path ,true, false);
    auto loader = NSDictionaryTextureLoader::defaultLoader();
    auto atlas = new (__FILE__, __LINE__) Atlas(str, loader, true);
    str.unown();
    return atlas;
}

Atlas* Atlas_load(const char* __counted_by(length) strdata, int length, const char* dir) {
    return new (__FILE__, __LINE__) Atlas(strdata, length, dir, NSDictionaryTextureLoader::defaultLoader(), true);
}

const char* peek_String(const String *self) {
    if (!self) {
        return nil;
    }
    return self->buffer();
}

SkeletonData* animationStateData_getData(AnimationStateData& self) {
    return self.getSkeletonData();
}

Skeleton* create_skeleton(SkeletonData& self) {
    return new (__FILE__, __LINE__) Skeleton(&self);
}
void dispose_skeleton(Skeleton* self) {
    delete (Skeleton *) self;
}
AnimationState* create_animationState(AnimationStateData& self) {
    return new (__FILE__, __LINE__) AnimationState(&self);
}
void dispose_animationState(AnimationState* self){
    delete (AnimationState*) self;
}
//template <typename T> T &peek_vector(Vector<T>& self, int index) {
//    return self[index];
//}
String& atlasPage_name(AtlasPage& self) {
    return self.name;
}

};

