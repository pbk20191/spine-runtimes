//
//  extension.c
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#include "src/extensions.h"
#include <spine/spine.h>
#include <spine/Version.h>
#include <spine/Debug.h>
#include "src/generated/types.h"


int32_t spine_major_version(void) {
	return SPINE_MAJOR_VERSION;
}

int32_t spine_minor_version(void) {
	return SPINE_MINOR_VERSION;
}

namespace {

	class SpineDelegateExtension : public spine::SpineExtension {

	public:
		spine::SpineExtension *imp;

		SpineDelegateExtension(spine::SpineExtension *imp) : imp(imp), spine::SpineExtension() {
		}

		SpineDelegateExtension() : SpineDelegateExtension(nullptr) {
		}

		void *_alloc(size_t size, const char *file, int line) override {
			return imp->_alloc(size, file, line);
		}

		void *_realloc(void *ptr, size_t size, const char *file, int line) override {
			return imp->_realloc(ptr, size, file, line);
		}
		void *_calloc(size_t size, const char *file, int line) override {
			return imp->_calloc(size, file, line);
		}
		void _free(void *mem, const char *file, int line) override {
			imp->_free(mem, file, line);
		}
		char *_readFile(const spine::String &path, int *length) override {
			return imp->_readFile(path, length);
		}

		void _beforeFree(void *ptr) override {
			imp->_beforeFree(ptr);
		}
	};

	class SpineDebugExtension : public spine::DebugExtension {
	private:
		spine::SpineExtension *imp;

	public:
		SpineDebugExtension(spine::SpineExtension *imp) : imp(imp), spine::DebugExtension(imp) {
		}

		void _beforeFree(void *ptr) override {
			imp->_beforeFree(ptr);
		};
	};

}


static SpineDelegateExtension wrapper;
static auto debugExtension = SpineDebugExtension(&wrapper);


void spine_enable_debug_extension(bool enable) {
	spine::SpineExtension *original = spine::SpineExtension::getInstance();
	if (wrapper.imp != original && original != &debugExtension) {
		wrapper.imp = original;
	}
	if (enable) {
		spine::SpineExtension::setInstance(&debugExtension);
	} else {
		spine::SpineExtension::setInstance(wrapper.imp);
	}
}

void spine_report_leaks(void) {
	auto extension = spine::SpineExtension::getInstance();
#ifdef RTTI_ENABLED
	auto _debugExtension = dynamic_cast<spine::DebugExtension *>(extension);
#else
	auto _debugExtension = static_cast<spine::DebugExtension *>(&debugExtension);
#endif
	if (_debugExtension) {
		_debugExtension->reportLeaks();
		fflush(stdout);
	}
}

spine::SpineExtension *__attribute__((weak)) spine::getDefaultExtension() {
	static spine::DefaultSpineExtension extension;
	return &extension;
}
