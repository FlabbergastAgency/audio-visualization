#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct Uniform {
    float scale;
    float aspectRatio;
    matrix_float2x2 rotationMatrix;
};

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut vertexShader(VertexIn in [[stage_in]],
                              constant Uniform &uniform [[buffer(1)]]) {
    
    float2 pos = in.position;
    pos = uniform.rotationMatrix * pos * uniform.scale;
    pos.x /= uniform.aspectRatio;
    
    VertexOut out;
    out.position = float4(pos, 0, 1);
    out.textureCoordinate = in.textureCoordinate;
    
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> albumTexture [[texture(0)]]) {
    constexpr sampler s(filter::linear,
                        address::clamp_to_edge);
    
    float4 color = albumTexture.sample(s, in.textureCoordinate);
    
    return color;
}
