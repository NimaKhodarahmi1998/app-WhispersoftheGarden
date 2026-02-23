//
//  WaterShader.metal
//  WhispersoftheGardenApp
//
//  Realistic, subtle water surface for the garden pool.
//  Renders a translucent animated overlay: layered waves, caustics,
//  specular highlights, and tap-triggered ripples.
//

#include <metal_stdlib>
using namespace metal;

// Must match WaterUniforms in WaterMetalView.swift
struct Uniforms {
    float  time;
    float  pad0;                    // padding for alignment
    float2 resolution;
    float4 ripples[8];              // xy = normalized pos, z = birthTime, w = unused
    int    rippleCount;
    int    pad1;
    float2 poolVertices[5];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// ─── Helpers ────────────────────────────────────────────────────────

// Simple hash for pseudo-random
static float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// Smooth noise
static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractional Brownian Motion — organic, natural patterns
static float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.1;
        amplitude *= 0.45;
    }
    return value;
}

// ─── Pool Polygon Masking ───────────────────────────────────────────

// Point-in-polygon via ray casting
static bool pointInPool(float2 p, constant float2 *verts) {
    bool inside = false;
    int j = 4;
    for (int i = 0; i < 5; i++) {
        float2 vi = verts[i];
        float2 vj = verts[j];
        if (((vi.y > p.y) != (vj.y > p.y)) &&
            (p.x < (vj.x - vi.x) * (p.y - vi.y) / (vj.y - vi.y) + vi.x)) {
            inside = !inside;
        }
        j = i;
    }
    return inside;
}

// Signed distance to the nearest polygon edge (approximate)
static float distToPoolEdge(float2 p, constant float2 *verts) {
    float minDist = 1e10;
    int j = 4;
    for (int i = 0; i < 5; i++) {
        float2 a = verts[j];
        float2 b = verts[i];
        float2 ab = b - a;
        float2 ap = p - a;
        float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
        float2 closest = a + t * ab;
        float d = length(p - closest);
        minDist = min(minDist, d);
        j = i;
    }
    return minDist;
}

// ─── Wave Height Field ──────────────────────────────────────────────

// Layered Gerstner-like waves — very gentle
static float waveHeight(float2 uv, float time) {
    float h = 0.0;

    // Wave 1: slow, broad swell
    h += sin(uv.x * 6.0 + uv.y * 3.0 + time * 0.4) * 0.012;
    // Wave 2: perpendicular drift
    h += sin(uv.x * 4.0 - uv.y * 7.0 + time * 0.55) * 0.008;
    // Wave 3: diagonal ripple
    h += sin(uv.x * 9.0 + uv.y * 5.0 - time * 0.35) * 0.006;
    // Wave 4: very fine shimmer
    h += sin(uv.x * 14.0 - uv.y * 11.0 + time * 0.8) * 0.003;
    // Wave 5: slow organic sway
    h += sin(uv.x * 2.5 + uv.y * 1.8 + time * 0.2) * 0.015;

    return h;
}

// Tap ripple contribution
static float rippleHeight(float2 uv, float4 ripple, float time) {
    float age = time - ripple.z;
    if (age < 0.0 || age > 3.5) return 0.0;

    float2 center = ripple.xy;
    float dist = length(uv - center);
    float speed = 0.12;
    float waveRadius = age * speed;
    float ringWidth = 0.025;

    // Concentric rings expanding outward
    float ring = sin((dist - waveRadius) * 120.0) * 0.5 + 0.5;
    // Gaussian envelope around the wavefront
    float envelope = exp(-pow((dist - waveRadius) / ringWidth, 2.0));
    // Decay over time
    float decay = exp(-age * 1.4);
    // Fade at distance
    float distFade = exp(-dist * 3.0);

    return ring * envelope * decay * distFade * 0.04;
}

// ─── Caustics ───────────────────────────────────────────────────────

static float caustics(float2 uv, float time) {
    // Two layers of distorted voronoi-like pattern
    float2 p1 = uv * 8.0 + float2(time * 0.06, time * 0.04);
    float2 p2 = uv * 6.0 - float2(time * 0.05, time * 0.07);

    float n1 = fbm(p1);
    float n2 = fbm(p2);

    // Interference pattern
    float c = n1 * n2;
    // Sharpen into caustic lines
    c = pow(c, 1.8) * 3.0;
    return clamp(c, 0.0, 1.0);
}

// ─── Vertex Shader ──────────────────────────────────────────────────

vertex VertexOut waterVertex(uint vid [[vertex_id]],
                             constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    float2 pos = vertices[vid];
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    out.uv.y = 1.0 - out.uv.y;  // flip Y for screen coords
    return out;
}

// ─── Fragment Shader ────────────────────────────────────────────────

fragment float4 waterFragment(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float time = u.time;

    // ── Pool masking ──
    if (!pointInPool(uv, u.poolVertices)) {
        return float4(0.0);
    }

    float edgeDist = distToPoolEdge(uv, u.poolVertices);
    float edgeFade = smoothstep(0.0, 0.04, edgeDist);

    // ── Wave height + ripples ──
    float h = waveHeight(uv, time);

    for (int i = 0; i < u.rippleCount && i < 8; i++) {
        h += rippleHeight(uv, u.ripples[i], time);
    }

    // ── Surface normal from height (central differences) ──
    float eps = 0.003;
    float hL = waveHeight(uv - float2(eps, 0.0), time);
    float hR = waveHeight(uv + float2(eps, 0.0), time);
    float hD = waveHeight(uv - float2(0.0, eps), time);
    float hU = waveHeight(uv + float2(0.0, eps), time);

    // Add ripple contributions to normal computation
    for (int i = 0; i < u.rippleCount && i < 8; i++) {
        hL += rippleHeight(uv - float2(eps, 0.0), u.ripples[i], time);
        hR += rippleHeight(uv + float2(eps, 0.0), u.ripples[i], time);
        hD += rippleHeight(uv - float2(0.0, eps), u.ripples[i], time);
        hU += rippleHeight(uv + float2(0.0, eps), u.ripples[i], time);
    }

    float2 normal = float2(hL - hR, hD - hU) / (2.0 * eps);

    // ── Specular highlights ──
    // Fake sun direction — slightly off-center for natural look
    float2 lightDir = normalize(float2(0.3, -0.5));
    float specular = dot(normalize(normal), lightDir);
    specular = pow(clamp(specular, 0.0, 1.0), 16.0) * 0.25;

    // Secondary soft highlight
    float2 lightDir2 = normalize(float2(-0.5, -0.3));
    float spec2 = dot(normalize(normal), lightDir2);
    spec2 = pow(clamp(spec2, 0.0, 1.0), 8.0) * 0.10;

    // ── Caustics ──
    float c = caustics(uv + normal * 0.5, time);
    c *= 0.08;  // very subtle

    // ── Water color ──
    // Deep teal base
    float3 deepColor  = float3(0.03, 0.08, 0.14);
    float3 shallowColor = float3(0.06, 0.16, 0.22);

    // Depth variation — center is deeper
    float2 poolCenter = float2(0.65, 0.82);
    float distFromCenter = length(uv - poolCenter);
    float depthFactor = smoothstep(0.0, 0.25, distFromCenter);
    float3 baseColor = mix(deepColor, shallowColor, depthFactor);

    // Add wave-driven color variation
    baseColor += float3(0.01, 0.025, 0.03) * h * 8.0;

    // Caustic light on surface
    float3 causticColor = float3(0.15, 0.25, 0.30) * c;

    // Specular highlights (warm white)
    float3 specColor = float3(0.9, 0.95, 1.0) * (specular + spec2);

    // Combine
    float3 finalColor = baseColor + causticColor + specColor;

    // ── Alpha ──
    // Base transparency — lets background image show through
    float alpha = 0.30;
    // Brighter where highlights are
    alpha += (specular + spec2) * 0.3;
    // Slight variation from waves
    alpha += h * 0.8;
    // Caustics add a touch
    alpha += c * 0.15;

    alpha = clamp(alpha, 0.0, 0.55);
    alpha *= edgeFade;

    return float4(finalColor, alpha);
}
