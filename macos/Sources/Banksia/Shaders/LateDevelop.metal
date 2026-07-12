#include <metal_stdlib>
using namespace metal;

struct LateDevelopUniforms {
    float exposure_ev;
    float contrast;
};

struct RasterData {
    float4 position [[position]];
    float2 texture_coordinate;
};

vertex RasterData banksia_fullscreen_vertex(uint vertex_id [[vertex_id]]) {
    constexpr float2 positions[] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0),
    };
    constexpr float2 texture_coordinates[] = {
        float2(0.0,  1.0),
        float2(2.0,  1.0),
        float2(0.0, -1.0),
    };
    return RasterData{
        float4(positions[vertex_id], 0.0, 1.0),
        texture_coordinates[vertex_id],
    };
}

fragment float4 banksia_late_develop_fragment(
    RasterData input [[stage_in]],
    texture2d<float> linear_rec2020 [[texture(0)]],
    sampler image_sampler [[sampler(0)]],
    constant LateDevelopUniforms& uniforms [[buffer(0)]])
{
    float3 value = linear_rec2020.sample(image_sampler, input.texture_coordinate).rgb;
    value *= exp2(uniforms.exposure_ev);
    if (uniforms.contrast > 0.0) {
        value = clamp(value, 0.0, 1.0);
        const float3 smooth = value * value * (3.0 - 2.0 * value);
        value = mix(value, smooth, uniforms.contrast);
    }

    const float3x3 rec2020_to_srgb = float3x3(
        float3( 1.660491, -0.124550, -0.018151),
        float3(-0.587641,  1.132900, -0.100579),
        float3(-0.072850, -0.008349,  1.118730));
    const float3 linear_srgb = clamp(rec2020_to_srgb * value, 0.0, 1.0);
    return float4(linear_srgb, 1.0);
}
