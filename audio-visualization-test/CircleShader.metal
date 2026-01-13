#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct Uniform {
    float scale;
    float aspectRatio;
    matrix_float2x2 rotationMatrix;
};

struct VertexOut {
    vector_float4 position [[position]];
    vector_float4 color;
};

vertex VertexOut vertexShader(const constant vector_float2 *vertexArray [[buffer(0)]],
                              const constant Uniform *uniform [[buffer(1)]],
                              unsigned int vid [[vertex_id]]) {
    
    Uniform uniformVertex = uniform[0];
    
    vector_float2 currentVertex = vertexArray[vid];
    currentVertex = uniformVertex.rotationMatrix * currentVertex * uniformVertex.scale;
    currentVertex.x /= uniformVertex.aspectRatio;
        
    VertexOut output;
        
    output.position = vector_float4(currentVertex, 0, 1);
    output.color = vector_float4(0, 0, 0, 1);
    
    return output;
}

fragment vector_float4 fragmentShader(VertexOut interpolated [[stage_in]]) {
    return interpolated.color;
}
