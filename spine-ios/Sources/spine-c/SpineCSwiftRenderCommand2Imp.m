//
//  SpineCSwiftRenderCommand2Imp.m
//  spine-ios
//
//  Created by 박병관 on 3/19/25.
//

#import "spine_public.h"

#import "private/SpineCSwiftRenderCommand2Imp.h"

@implementation SpineCSwiftRenderCommand2Imp

-(NSInteger) positionCount {
    return self->_positions.length / sizeof(float);
}

- (const int *)colors {
    return self->_colors.bytes;
}

- (NSInteger)colorCount {
    return self->_colors.length / sizeof(int);
}

-(NSInteger) uvCount {
    return self->_uvs.length / sizeof(float);
}

-(NSInteger) indexCount {
    return self->_indices.length / sizeof(unsigned short);
}

- (const float *)positions {
    return self->_positions.bytes;
}

- (const float *)uvs {
    return self->_uvs.bytes;
}

- (const unsigned short *)indices {
    return self->_indices.bytes;
}

@end

