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

#define SPINE_FORWARD_OPAQUE_TYPE(type) typedef struct type##_wrapper* type;


#endif /* spine_c_prefix_h */
