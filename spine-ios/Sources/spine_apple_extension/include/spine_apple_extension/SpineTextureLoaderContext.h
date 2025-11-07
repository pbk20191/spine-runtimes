//
//  SpineTextureLoaderContext.h
//  spine-ios
//
//  Created by 박병관 on 7/24/25.
//

#ifndef SpineTextureLoaderContext_h
#define SpineTextureLoaderContext_h

#include <spine-c.h>

//SPINE_FORWARD_OPAQUE_TYPE(spine_atlas_page)

typedef struct SpineTextureLoaderContext {
	void *_Nullable (*_Nullable initialize)(const void *_Nullable input);
	void (*_Nullable deinitialize)(void *_Nullable loader);
	void (*_Nullable load)(spine_atlas_page _Nonnull page, const char *__null_terminated _Nonnull path, void *_Nullable context);
	void (*_Nullable unload)(void *_Nullable texture, void *_Nullable context);
	void *_Nullable info;
} SpineTextureLoaderContext;


#endif /* SpineTextureLoaderContext_h */
