//
//  WaterShader.metal
//  WhispersoftheGardenApp
//
//  Realistic, subtle water surface for the garden pool.
//  Renders a translucent animated overlay: layered waves, caustics,
//  specular highlights, and perspective-correct tap-triggered ripples.
//

#include <metal_stdlib>
using namespace metal;

// Must match WaterUniforms in WaterMetalView.swift
struct Uniforms {
    float  time;
    float  pad0;
    float2 resolution;
    float4 ripples[8];              // xy = normalized pos, z = birthTime, w = random seed
    int    rippleCount;
    int    pad1;
    float2 poolVertices[5];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// ─── Helpers ────────────────────────────────────────────────────────

static float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

static float hash1(float p) {
    return fract(sin(p * 78.233) * 43758.5453);
}

// Smooth value noise
static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);  // smoothstep

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Gradient noise (smoother, more directional)
static float gnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);  // quintic smoothstep

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractional Brownian Motion — 5 octaves for richer detail
static float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float2x2 rot = float2x2(0.866, 0.5, -0.5, 0.866);  // 30° rotation between octaves
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p = rot * p * 2.05 + float2(1.7, 9.2);
        amplitude *= 0.48;
    }
    return value;
}

// Turbulence (abs-valued fbm for vein-like patterns)
static float turbulence(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * abs(noise(p) * 2.0 - 1.0);
        p *= 2.1;
        amplitude *= 0.45;
    }
    return value;
}

// ─── Pool Polygon Masking ───────────────────────────────────────────

static bool pointInPool(float2 p, thread float2 *verts) {
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

static float distToPoolEdge(float2 p, thread float2 *verts) {
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

// ─── Perspective Transform ──────────────────────────────────────────

// The pool is viewed at ~45° from above. Y positions closer to the top
// of the pool (lower Y in screen, higher Y in normalized) are "farther away".
// We squash the Y axis based on vertical position to fake perspective.

// Maps screen UV to a perspective-corrected "water surface" coordinate.
// Top of pool (y ~0.65) is far, bottom (y ~0.95) is near.
static float perspectiveSquash(float y) {
    // How much to compress Y based on vertical position
    // Near bottom of pool: squash = 1.0 (no distortion)
    // Near top: squash = 0.45 (heavily compressed — farther away)
    float poolTop = 0.65;
    float poolBottom = 0.95;
    float t = clamp((y - poolTop) / (poolBottom - poolTop), 0.0, 1.0);
    return mix(0.40, 1.0, t);
}

// Perspective-adjusted distance between two points on the water surface
static float perspDist(float2 uv, float2 center) {
    float2 delta = uv - center;
    // Squash the Y component at the fragment position
    float squash = perspectiveSquash(uv.y);
    delta.y /= squash;
    return length(delta);
}

// ─── Wave Height Field ──────────────────────────────────────────────

static float waveHeight(float2 uv, float time) {
    float h = 0.0;

    // Scale UV for perspective — waves appear tighter at top of pool
    float pScale = perspectiveSquash(uv.y);
    float2 puv = float2(uv.x, uv.y / pScale);

    // Layer 1: slow, broad swell
    h += sin(puv.x * 5.5 + puv.y * 2.8 + time * 0.35) * 0.014;
    // Layer 2: cross-swell
    h += sin(puv.x * 3.5 - puv.y * 6.0 + time * 0.50) * 0.009;
    // Layer 3: diagonal detail
    h += sin(puv.x * 8.5 + puv.y * 4.5 - time * 0.30) * 0.007;
    // Layer 4: fine shimmer
    h += sin(puv.x * 13.0 - puv.y * 10.0 + time * 0.75) * 0.004;
    // Layer 5: very slow organic drift
    h += sin(puv.x * 2.2 + puv.y * 1.5 + time * 0.18) * 0.016;

    // Micro-texture: noise-driven surface detail (the "texture" feel)
    float micro = gnoise(puv * 18.0 + float2(time * 0.15, time * 0.10)) * 0.006;
    micro += gnoise(puv * 32.0 - float2(time * 0.08, time * 0.12)) * 0.003;
    h += micro;

    return h;
}

// ─── Tap Ripples (Perspective-Correct, Randomized) ──────────────────

static float rippleHeight(float2 uv, float4 ripple, float time) {
    float age = time - ripple.z;
    if (age < 0.0 || age > 4.0) return 0.0;

    float seed = ripple.w;

    // Per-ripple variation from seed
    float speedVar    = 0.11 + hash1(seed) * 0.07;           // 0.11–0.18
    float freqVar     = 85.0 + hash1(seed * 2.7) * 65.0;    // 85–150 (ring density)
    float ampVar      = 0.045 + hash1(seed * 5.1) * 0.035;  // 0.045–0.08
    float widthVar    = 0.022 + hash1(seed * 3.3) * 0.016;   // 0.022–0.038
    float decayVar    = 1.0 + hash1(seed * 7.9) * 0.5;       // 1.0–1.5 (slower decay)

    float2 center = ripple.xy;

    // Perspective-correct distance: elliptical rings matching pool angle
    float dist = perspDist(uv, center);

    float waveRadius = age * speedVar;

    // Multiple concentric rings (not just one sine)
    float ring1 = sin((dist - waveRadius) * freqVar) * 0.5 + 0.5;
    float ring2 = sin((dist - waveRadius * 0.85) * freqVar * 1.3 + 1.0) * 0.3;

    // Gaussian envelope around the wavefront
    float envelope = exp(-pow((dist - waveRadius) / widthVar, 2.0));
    // Secondary wavefront (trailing ring)
    float trailRadius = waveRadius * 0.6;
    float trailEnvelope = exp(-pow((dist - trailRadius) / (widthVar * 1.5), 2.0)) * 0.4;

    // Decay over time
    float decay = exp(-age * decayVar);
    // Fade at distance (gentler falloff = ripples travel further)
    float distFade = exp(-dist * 1.8);

    float h = (ring1 * envelope + ring2 * trailEnvelope) * decay * distFade * ampVar;

    // Add tiny asymmetric wobble from noise (no ripple is perfectly circular)
    float wobble = gnoise(float2(atan2(uv.y - center.y, uv.x - center.x) * 3.0,
                                  dist * 20.0 + seed)) * 0.18;
    h *= (1.0 + wobble);

    return h;
}

// ─── Caustics ───────────────────────────────────────────────────────

static float caustics(float2 uv, float time) {
    // Apply perspective to caustic coordinates
    float pScale = perspectiveSquash(uv.y);
    float2 puv = float2(uv.x, uv.y / pScale);

    // Three layers for richer pattern
    float2 p1 = puv * 9.0 + float2(time * 0.055, time * 0.035);
    float2 p2 = puv * 7.0 - float2(time * 0.045, time * 0.065);
    float2 p3 = puv * 12.0 + float2(time * 0.03, -time * 0.04);

    float n1 = fbm(p1);
    float n2 = fbm(p2);
    float n3 = turbulence(p3);

    // Interference: multiply two layers, add turbulence for vein-like detail
    float c = n1 * n2;
    c = pow(c, 1.6) * 2.8;
    c += n3 * 0.12;

    return clamp(c, 0.0, 1.0);
}

// ─── Surface Texture (micro-ripple detail) ──────────────────────────

static float surfaceTexture(float2 uv, float time) {
    float pScale = perspectiveSquash(uv.y);
    float2 puv = float2(uv.x, uv.y / pScale);

    // Layered noise at different scales for organic surface texture
    float t1 = gnoise(puv * 24.0 + float2(time * 0.12, time * 0.08));
    float t2 = gnoise(puv * 40.0 - float2(time * 0.06, time * 0.10));
    float t3 = noise(puv * 55.0 + float2(-time * 0.09, time * 0.05));

    return t1 * 0.5 + t2 * 0.3 + t3 * 0.2;
}

// ─── Vertex Shader ──────────────────────────────────────────────────

vertex VertexOut waterVertex(uint vid [[vertex_id]],
                             constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    float2 pos = vertices[vid];
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    out.uv.y = 1.0 - out.uv.y;
    return out;
}

// ─── Fragment Shader ────────────────────────────────────────────────

fragment float4 waterFragment(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float time = u.time;

    // ── Pool masking ──
    float2 verts[5];
    verts[0] = u.poolVertices[0];
    verts[1] = u.poolVertices[1];
    verts[2] = u.poolVertices[2];
    verts[3] = u.poolVertices[3];
    verts[4] = u.poolVertices[4];

    if (!pointInPool(uv, verts)) {
        return float4(0.0);
    }

    float edgeDist = distToPoolEdge(uv, verts);
    float edgeFade = smoothstep(0.0, 0.035, edgeDist);

    // ── Wave height + ripples ──
    float h = waveHeight(uv, time);

    for (int i = 0; i < u.rippleCount && i < 8; i++) {
        h += rippleHeight(uv, u.ripples[i], time);
    }

    // ── Surface normal from height (central differences) ──
    float eps = 0.002;
    float hL = waveHeight(uv - float2(eps, 0.0), time);
    float hR = waveHeight(uv + float2(eps, 0.0), time);
    float hD = waveHeight(uv - float2(0.0, eps), time);
    float hU = waveHeight(uv + float2(0.0, eps), time);

    for (int i = 0; i < u.rippleCount && i < 8; i++) {
        hL += rippleHeight(uv - float2(eps, 0.0), u.ripples[i], time);
        hR += rippleHeight(uv + float2(eps, 0.0), u.ripples[i], time);
        hD += rippleHeight(uv - float2(0.0, eps), u.ripples[i], time);
        hU += rippleHeight(uv + float2(0.0, eps), u.ripples[i], time);
    }

    float2 normal = float2(hL - hR, hD - hU) / (2.0 * eps);

    // ── Surface texture contribution to normals ──
    float tex = surfaceTexture(uv, time);
    float texL = surfaceTexture(uv - float2(eps, 0.0), time);
    float texR = surfaceTexture(uv + float2(eps, 0.0), time);
    float texD = surfaceTexture(uv - float2(0.0, eps), time);
    float texU = surfaceTexture(uv + float2(0.0, eps), time);
    float2 texNormal = float2(texL - texR, texD - texU) / (2.0 * eps);

    // Blend texture normals into surface normals (subtle)
    normal += texNormal * 0.25;

    // ── Specular highlights ──
    // Primary: upper-left light source
    float2 lightDir = normalize(float2(0.35, -0.55));
    float specular = dot(normalize(normal), lightDir);
    specular = pow(clamp(specular, 0.0, 1.0), 20.0) * 0.22;

    // Secondary: softer fill from opposite side
    float2 lightDir2 = normalize(float2(-0.4, -0.35));
    float spec2 = dot(normalize(normal), lightDir2);
    spec2 = pow(clamp(spec2, 0.0, 1.0), 10.0) * 0.08;

    // Broad glint (very soft, wide highlight for sky reflection)
    float spec3 = dot(normalize(normal), normalize(float2(0.0, -1.0)));
    spec3 = pow(clamp(spec3, 0.0, 1.0), 4.0) * 0.04;

    float totalSpec = specular + spec2 + spec3;

    // ── Caustics ──
    float c = caustics(uv + normal * 0.4, time);
    c *= 0.12;

    // ── Water color ──
    float3 deepColor    = float3(0.03, 0.12, 0.32);
    float3 shallowColor = float3(0.06, 0.20, 0.40);
    float3 tileHintColor = float3(0.04, 0.15, 0.35);

    // Depth: center is deeper
    float2 poolCenter = float2(0.65, 0.82);
    float distFromCenter = length(uv - poolCenter);
    float depthFactor = smoothstep(0.0, 0.22, distFromCenter);
    float3 baseColor = mix(deepColor, shallowColor, depthFactor);

    // Subtle color variation from noise (breaks uniformity)
    float colorNoise = fbm(uv * 5.0 + float2(time * 0.02, -time * 0.01));
    baseColor = mix(baseColor, tileHintColor, colorNoise * 0.25);

    // Surface texture adds subtle brightness variation
    baseColor += float3(0.006, 0.014, 0.025) * (tex - 0.5);

    // Wave-driven color shift
    baseColor += float3(0.008, 0.02, 0.03) * h * 6.0;

    // Caustic light (blue-tinted)
    float3 causticColor = float3(0.10, 0.25, 0.45) * c;

    // Specular (warm white with slight blue tint)
    float3 specColor = float3(0.85, 0.92, 1.0) * totalSpec;

    // Combine
    float3 finalColor = baseColor + causticColor + specColor;

    // ── Alpha ──
    float alpha = 0.38;
    alpha += totalSpec * 0.35;
    alpha += h * 0.6;
    alpha += c * 0.2;
    alpha += (tex - 0.5) * 0.06;  // texture adds slight alpha variation

    alpha = clamp(alpha, 0.0, 0.65);
    alpha *= edgeFade;

    return float4(finalColor, alpha);
}
