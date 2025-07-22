//
//  extension.h
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#ifndef extension_h
#define extension_h
#include "src/generated/types.h"
#include "src/base.h"


SPINE_C_API int32_t spine_major_version(void);
SPINE_C_API int32_t spine_minor_version(void);

SPINE_C_API __attribute__((weak)) void spine_enable_debug_extension(bool enable);
SPINE_C_API __attribute__((weak)) void spine_report_leaks(void);

#endif /* extension_h */
