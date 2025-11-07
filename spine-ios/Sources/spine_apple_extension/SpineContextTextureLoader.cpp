//
//  SpineCTextureLoader.cpp
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#include "spine_apple_extension/SpineContextTextureLoader.hpp"
#include <spine/spine.h>

void spine::SpineContextTextureLoader::load(spine::AtlasPage &page, const spine::String &path) {
	if (_context.load) {
		auto c_page = reinterpret_cast<spine_atlas_page>(&page);
		_context.load(c_page, path.buffer(), _context.info);
	}
}
void spine::SpineContextTextureLoader::unload(void *texture) {
	if (_context.unload) {
		_context.unload(texture, _context.info);
	}
}

spine::SpineContextTextureLoader::~SpineContextTextureLoader() {
	if (_context.deinitialize) {
		_context.deinitialize(_context.info);
	}
}

static inline SpineTextureLoaderContext initialize_context(const SpineTextureLoaderContext &context) {
	SpineTextureLoaderContext result = context;

	if (context.initialize) {
		result.info = context.initialize(context.info);
	}

	return result;
}

spine::SpineContextTextureLoader::SpineContextTextureLoader(const SpineTextureLoaderContext &table)
	: _context(initialize_context(table)), spine::TextureLoader() {
}

const SpineTextureLoaderContext &spine::SpineContextTextureLoader::getContext() const {
	return _context;
}
