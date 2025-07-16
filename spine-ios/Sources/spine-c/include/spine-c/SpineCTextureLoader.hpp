//
//  SpineCTextureLoader.hpp
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

#ifndef SpineCTextureLoader_hpp
#define SpineCTextureLoader_hpp
#if __cplusplus
#include <spine/spine.h>
#include "texture_loader.h"

namespace spine {
    class SpineCTextureLoader: public spine::TextureLoader {
      
    public:
        SpineCTextureLoader(const SpineTextureLoaderContext& vtable);
        ~SpineCTextureLoader() override;
        void load(spine::AtlasPage &page, const spine::String &path) override;
        void unload(void * _Nullable texture) override;
        const SpineTextureLoaderContext& getContext() const;
    private:
        const SpineTextureLoaderContext _context;
    };
}

#endif
#endif /* SpineCTextureLoader_hpp */
