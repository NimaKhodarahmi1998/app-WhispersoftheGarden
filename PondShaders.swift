//
//  SwiftUIView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 12/02/26.
//

enum PondShaders {
    static let mslSource = #"""
#include <metal_stdlib>
using namespace metal;

struct VSOut { float4 position [[position]]; float2 uv; };
struct Uniforms { float time; float aspect; };

vertex VSOut pond_vertex(const device float *v [[buffer(0)]], uint vid [[vertex_id]]) {
    VSOut o;
    o.position = float4(v[vid*4+0], v[vid*4+1], 0, 1);
    o.uv = float2(v[vid*4+2], v[vid*4+3]);
    return o;
}

fragment float4 pond_fragment(VSOut in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
    float2 p = in.uv * 2.0 - 1.0;
    p.x *= u.aspect;

    float t = u.time;
    float w = sin((p.x*6 + p.y*4) + t*1.2) * 0.18
            + sin((p.x*-5 + p.y*7) + t*0.9) * 0.14
            + sin(length(p)*14 - t*2.0) * 0.10;

    float3 base = float3(0.03, 0.18, 0.20);
    float3 hi   = float3(0.10, 0.40, 0.42);

    float shade = 0.5 + 0.5*w;
    float3 col = mix(base, hi, shade*0.35);

    // tiny “sparkle”
    col += pow(max(0.0, w), 6.0) * 0.25;

    return float4(col, 1.0);
}
"""#
}

