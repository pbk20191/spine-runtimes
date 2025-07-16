//
//  _extension.cpp
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#include <spine/Extension.h>

spine::SpineExtension* __attribute__((weak)) spine::getDefaultExtension()  {
    static spine::DefaultSpineExtension extension;
    return &extension;
}
