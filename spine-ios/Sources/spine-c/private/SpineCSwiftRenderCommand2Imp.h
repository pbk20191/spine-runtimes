//
//  SpineCSwiftRenderCommand2Imp.h
//  spine-ios
//
//  Created by 박병관 on 3/19/25.
//
#include <Foundation/Foundation.h>
#ifndef SpineCSwiftRenderCommand2Imp_h
#define SpineCSwiftRenderCommand2Imp_h
#include <spine/SlotData.h>
@protocol SpineCRenderCommand;

@interface SpineCSwiftRenderCommand2Imp : NSObject <SpineCRenderCommand>{
@public
    NSMutableData* _positions;
    NSMutableData* _uvs;
    NSMutableData* _colors;
    NSMutableData* _indices;
    spBlendMode _blendMode;
    int _textureIndex;
    bool _pma;
    NSString* _pageName;
}

@property (readonly) spBlendMode blendMode;
@property (readonly) int textureIndex;
@property (readonly) bool pma;
@property (readonly) NSString* pageName;


@end

#endif /* SpineCSwiftRenderCommand2Imp_h */
