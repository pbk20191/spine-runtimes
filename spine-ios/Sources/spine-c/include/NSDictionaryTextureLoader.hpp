//
//  NSDictionaryTextureLoader.hpp
//  spine-ios
//
//  Created by 박병관 on 7/14/25.
//

#ifndef NSDictionaryTextureLoader_hpp
#define NSDictionaryTextureLoader_hpp


#ifdef __cplusplus
#include <spine/spine.h>

namespace spine_support {




class NSDictionaryTextureLoader: public spine::TextureLoader {

public:
    void load(spine::AtlasPage &page, const spine::String &path) override;
    
    void unload(void * _Null_unspecified texture) override;
    
    
    static spine::TextureLoader* _Nonnull  defaultLoader(void);
};




}

#endif
#endif /* NSDictionaryTextureLoader_hpp */
