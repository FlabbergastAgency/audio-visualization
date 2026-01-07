#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct LoudnessUniform {
    float scale;
    float aspectRatio;
};

struct RotationUniform {
    float angle;
    matrix_float2x2 rotationMatrix;
};

struct VertexOut {
    vector_float4 position [[position]];
    vector_float4 color;
};

vertex VertexOut vertexShader(const constant vector_float2 *vertexArray [[buffer(0)]],
                              const constant LoudnessUniform *loudnessUniform [[buffer(1)]],
                              const constant RotationUniform *rotationUniform [[buffer(2)]],
                              unsigned int vid [[vertex_id]]) {
    
    LoudnessUniform loudnessUniformVertex = loudnessUniform[0];
    RotationUniform rotationUniformVertex = rotationUniform[0];
    
    vector_float2 currentVertex = vertexArray[vid];
    currentVertex = rotationUniformVertex.rotationMatrix * currentVertex * loudnessUniformVertex.scale;
    currentVertex.x /= loudnessUniformVertex.aspectRatio;
        
    VertexOut output;
        
    output.position = vector_float4(currentVertex, 0, 1);
    output.color = vector_float4(0, 0, 0, 1);
    
    return output;
}

fragment vector_float4 fragmentShader(VertexOut interpolated [[stage_in]]) {
    return interpolated.color;
}
