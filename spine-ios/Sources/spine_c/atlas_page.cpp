#include "atlas_page.h"
#include <spine/spine.h>

using namespace spine;

spine_atlas_page spine_atlas_page_create(const char* inName) {
    return (spine_atlas_page) new (__FILE__, __LINE__) AtlasPage(String(inName));
}

void spine_atlas_page_dispose(spine_atlas_page self) {
    delete (AtlasPage*)self;
}

const char* spine_atlas_page_get_name(spine_atlas_page self) {
    return ((AtlasPage*)self)->name.buffer();
}

void spine_atlas_page_set_name(spine_atlas_page self, const char* value) {
    ((AtlasPage*)self)->name = String(value);
}

const char* spine_atlas_page_get_texture_path(spine_atlas_page self) {
    return ((AtlasPage*)self)->texturePath.buffer();
}

void spine_atlas_page_set_texture_path(spine_atlas_page self, const char* value) {
    ((AtlasPage*)self)->texturePath = String(value);
}

spine_format spine_atlas_page_get_format(spine_atlas_page self) {
    return (spine_format)((AtlasPage*)self)->format;
}

void spine_atlas_page_set_format(spine_atlas_page self, spine_format value) {
    ((AtlasPage*)self)->format = (Format)value;
}

spine_texture_filter spine_atlas_page_get_min_filter(spine_atlas_page self) {
    return (spine_texture_filter)((AtlasPage*)self)->minFilter;
}

void spine_atlas_page_set_min_filter(spine_atlas_page self, spine_texture_filter value) {
    ((AtlasPage*)self)->minFilter = (TextureFilter)value;
}

spine_texture_filter spine_atlas_page_get_mag_filter(spine_atlas_page self) {
    return (spine_texture_filter)((AtlasPage*)self)->magFilter;
}

void spine_atlas_page_set_mag_filter(spine_atlas_page self, spine_texture_filter value) {
    ((AtlasPage*)self)->magFilter = (TextureFilter)value;
}

spine_texture_wrap spine_atlas_page_get_u_wrap(spine_atlas_page self) {
    return (spine_texture_wrap)((AtlasPage*)self)->uWrap;
}

void spine_atlas_page_set_u_wrap(spine_atlas_page self, spine_texture_wrap value) {
    ((AtlasPage*)self)->uWrap = (TextureWrap)value;
}

spine_texture_wrap spine_atlas_page_get_v_wrap(spine_atlas_page self) {
    return (spine_texture_wrap)((AtlasPage*)self)->vWrap;
}

void spine_atlas_page_set_v_wrap(spine_atlas_page self, spine_texture_wrap value) {
    ((AtlasPage*)self)->vWrap = (TextureWrap)value;
}

int spine_atlas_page_get_width(spine_atlas_page self) {
    return ((AtlasPage*)self)->width;
}

void spine_atlas_page_set_width(spine_atlas_page self, int value) {
    ((AtlasPage*)self)->width = value;
}

int spine_atlas_page_get_height(spine_atlas_page self) {
    return ((AtlasPage*)self)->height;
}

void spine_atlas_page_set_height(spine_atlas_page self, int value) {
    ((AtlasPage*)self)->height = value;
}

bool spine_atlas_page_get_pma(spine_atlas_page self) {
    return ((AtlasPage*)self)->pma;
}

void spine_atlas_page_set_pma(spine_atlas_page self, bool value) {
    ((AtlasPage*)self)->pma = value;
}

int spine_atlas_page_get_index(spine_atlas_page self) {
    return ((AtlasPage*)self)->index;
}

void spine_atlas_page_set_index(spine_atlas_page self, int value) {
    ((AtlasPage*)self)->index = value;
}

void * spine_atlas_page_get_texture(spine_atlas_page self) {
    return ((AtlasPage*)self)->texture;
}

void spine_atlas_page_set_texture(spine_atlas_page self, void * value) {
    ((AtlasPage*)self)->texture = (void*)value;
}
