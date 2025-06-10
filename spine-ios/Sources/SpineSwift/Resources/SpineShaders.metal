#include <metal_stdlib>
#include <simd/simd.h> 
using namespace metal;

#import "../../SpineShadersStructs/SpineShadersStructs.h"

constant bool kPremultiplyAlpha [[function_constant(0)]];

struct RasterizerData {
    simd_float4 position [[position]];
    simd_float2 textureCoordinate;
    simd_half4 lightColor;
    simd_half4 darkColor;
};

#if __METAL_VERSION__ >= 230
    #define VERTEX_STAGE [[vertex]]
    #define FRAGMENT_STAGE [[fragment]]
#else
    #define VERTEX_STAGE
    #define FRAGMENT_STAGE
#endif

VERTEX_STAGE
vertex RasterizerData
spine_vertexShader(uint vertexID [[vertex_id]],
             constant SpineAdvancedVertex *vertices [[buffer(SpineVertexInputIndexVertices)]],
             constant SpineTransform &transform [[buffer(SpineVertexInputIndexTransform)]],
             constant vector_uint2 &viewportSizePointer [[buffer(SpineVertexInputIndexViewportSize)]])
{
    RasterizerData out;

    simd_float2 pixelSpacePosition = vertices[vertexID].position.xy;

    simd_float2 viewportSize = simd_float2(viewportSizePointer);

    out.position = simd_float4(0.0, 0.0, 0.0, 1.0);

    out.position.xy = pixelSpacePosition;
    out.position.xy *= transform.scale;
    out.position.xy += transform.translation * transform.scale + transform.offset;
    out.position.xy /= viewportSize / 2;
    
    //out.lightColor = vertices[vertexID].color;
    uint light = as_type<uint>(vertices[vertexID].color);
    uint dark  = as_type<uint>(vertices[vertexID].darkColor);

    out.lightColor = half4(
        half((light >> 16) & 0xFF) / 255.0h,
        half((light >> 8)  & 0xFF) / 255.0h,
        half((light >> 0)  & 0xFF) / 255.0h,
        half((light >> 24) & 0xFF) / 255.0h
    );

    out.darkColor = half4(
        half((dark >> 16) & 0xFF) / 255.0h,
        half((dark >> 8)  & 0xFF) / 255.0h,
        half((dark >> 0)  & 0xFF) / 255.0h,
        half((dark >> 24) & 0xFF) / 255.0h
    );
    out.textureCoordinate = vertices[vertexID].uv;
    
    return out;
}

FRAGMENT_STAGE
fragment simd_half4
spine_fragmentShader(
                     RasterizerData in [[stage_in]],
                     const texture2d<half, access::sample> colorTexture [[ texture(SpineTextureIndexBaseColor) ]],
                     const sampler textureSampler [[ sampler(0) ]]
                     )
{

    const half4 rawSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    const half4 tex = half4(rawSample.rgb * (kPremultiplyAlpha ? rawSample.a : 1.0h), rawSample.a);

    half4 src;
    src.a = tex.a * in.lightColor.a;
    src.rgb = ((tex.a - 1.0h) * in.darkColor.a + 1.0h - tex.rgb) * in.darkColor.rgb + tex.rgb * in.lightColor.rgb;

    return half4(src);
}
