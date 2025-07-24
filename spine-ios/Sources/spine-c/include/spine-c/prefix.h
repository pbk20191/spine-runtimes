//
//  prefix.h
//  spine-ios
//
//  Created by 박병관 on 7/24/25.
//

#ifndef spine_c_prefix_h
#define spine_c_prefix_h

#include "src/base.h"


#ifndef __counted_by
#define __counted_by(length)
#endif

#ifndef __null_terminated
#define __null_terminated
#endif

#define SPINE_FORWARD_OPAQUE_TYPE(type) typedef struct type##_wrapper *type;

#ifdef __cplusplus
#if defined(__clang__)
#if __has_feature(cxx_rtti)
#define RTTI_ENABLED
#endif
#elif defined(__GNUC__)
#if defined(__GXX_RTTI)
#define RTTI_ENABLED
#endif
#elif defined(_MSC_VER)
#if defined(_CPPRTTI)
#define RTTI_ENABLED
#endif
#endif
#endif

#endif /* spine_c_prefix_h */
