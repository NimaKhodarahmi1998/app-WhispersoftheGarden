//
//  WaterMetalView.swift
//  WhispersoftheGardenApp
//
//  MTKView-based water renderer wrapped for SwiftUI (iOS 16+).
//  Shader source compiled at runtime (Swift Playgrounds has no .metal support).
//

import SwiftUI
import MetalKit

// MARK: - Uniforms (must match shader layout)

struct WaterUniforms {
    var time: Float = 0
    var pad0: Float = 0
    var resolution: SIMD2<Float> = .zero
    var ripples: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
                  SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) =
        (.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero)
    var rippleCount: Int32 = 0
    var pad1: Int32 = 0
    var poolVertices: (SIMD2<Float>, SIMD2<Float>, SIMD2<Float>,
                       SIMD2<Float>, SIMD2<Float>) = (
        SIMD2<Float>(0.53, 0.65),
        SIMD2<Float>(1.1,  0.73),
        SIMD2<Float>(1.0,  1.01),
        SIMD2<Float>(0.67, 0.92),
        SIMD2<Float>(0.21, 0.80)
    )
}

// MARK: - Ripple Data

private struct ActiveRipple {
    var position: SIMD2<Float>
    var birthTime: Float
    var seed: Float
}

// MARK: - Bridge (SwiftUI → Metal communication)

@MainActor
final class WaterRendererBridge {
    fileprivate var renderer: WaterRenderer?

    func addRipple(at normalizedPoint: CGPoint) {
        renderer?.addRipple(at: SIMD2<Float>(Float(normalizedPoint.x),
                                              Float(normalizedPoint.y)))
    }
}

// MARK: - Shader Source

private let waterShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float  time;
    float  pad0;
    float2 resolution;
    float4 ripples[8];
    int    rippleCount;
    int    pad1;
    float2 poolVertices[5];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

static float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

static float hash1(float p) {
    return fract(sin(p * 78.233) * 43758.5453);
}

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

static float gnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float2x2 rot = float2x2(0.866, 0.5, -0.5, 0.866);
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p = rot * p * 2.05 + float2(1.7, 9.2);
        amplitude *= 0.48;
    }
    return value;
}

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

static float perspectiveSquash(float y) {
    float poolTop = 0.65;
    float poolBottom = 0.95;
    float t = clamp((y - poolTop) / (poolBottom - poolTop), 0.0, 1.0);
    return mix(0.40, 1.0, t);
}

static float perspDist(float2 uv, float2 center) {
    float2 delta = uv - center;
    float squash = perspectiveSquash(uv.y);
    delta.y /= squash;
    return length(delta);
}

static float waveHeight(float2 uv, float time) {
    float h = 0.0;
    float pScale = perspectiveSquash(uv.y);
    float2 puv = float2(uv.x, uv.y / pScale);

    h += sin(puv.x * 5.5 + puv.y * 2.8 + time * 0.35) * 0.014;
    h += sin(puv.x * 3.5 - puv.y * 6.0 + time * 0.50) * 0.009;
    h += sin(puv.x * 8.5 + puv.y * 4.5 - time * 0.30) * 0.007;
    h += sin(puv.x * 13.0 - puv.y * 10.0 + time * 0.75) * 0.004;
    h += sin(puv.x * 2.2 + puv.y * 1.5 + time * 0.18) * 0.016;

    float micro = gnoise(puv * 18.0 + float2(time * 0.15, time * 0.10)) * 0.006;
    micro += gnoise(puv * 32.0 - float2(time * 0.08, time * 0.12)) * 0.003;
    h += micro;

    return h;
}

static float rippleHeight(float2 uv, float4 ripple, float time) {
    float age = time - ripple.z;
    if (age < 0.0 || age > 4.0) return 0.0;

    float seed = ripple.w;
    float speedVar    = 0.11 + hash1(seed) * 0.07;
    float freqVar     = 85.0 + hash1(seed * 2.7) * 65.0;
    float ampVar      = 0.045 + hash1(seed * 5.1) * 0.035;
    float widthVar    = 0.022 + hash1(seed * 3.3) * 0.016;
    float decayVar    = 1.0 + hash1(seed * 7.9) * 0.5;

    float2 center = ripple.xy;
    float dist = perspDist(uv, center);
    float waveRadius = age * speedVar;

    float ring1 = sin((dist - waveRadius) * freqVar) * 0.5 + 0.5;
    float ring2 = sin((dist - waveRadius * 0.85) * freqVar * 1.3 + 1.0) * 0.3;

    float envelope = exp(-pow((dist - waveRadius) / widthVar, 2.0));
    float trailRadius = waveRadius * 0.6;
    float trailEnvelope = exp(-pow((dist - trailRadius) / (widthVar * 1.5), 2.0)) * 0.4;

    float decay = exp(-age * decayVar);
    float distFade = exp(-dist * 1.8);

    float h = (ring1 * envelope + ring2 * trailEnvelope) * decay * distFade * ampVar;

    float wobble = gnoise(float2(atan2(uv.y - center.y, uv.x - center.x) * 3.0,
                                  dist * 20.0 + seed)) * 0.18;
    h *= (1.0 + wobble);

    return h;
}

static float caustics(float2 uv, float time) {
    float pScale = perspectiveSquash(uv.y);
    float2 puv = float2(uv.x, uv.y / pScale);

    float2 p1 = puv * 9.0 + float2(time * 0.055, time * 0.035);
    float2 p2 = puv * 7.0 - float2(time * 0.045, time * 0.065);
    float2 p3 = puv * 12.0 + float2(time * 0.03, -time * 0.04);

    float n1 = fbm(p1);
    float n2 = fbm(p2);
    float n3 = turbulence(p3);

    float c = n1 * n2;
    c = pow(c, 1.6) * 2.8;
    c += n3 * 0.12;

    return clamp(c, 0.0, 1.0);
}

static float surfaceTexture(float2 uv, float time) {
    float pScale = perspectiveSquash(uv.y);
    float2 puv = float2(uv.x, uv.y / pScale);

    float t1 = gnoise(puv * 24.0 + float2(time * 0.12, time * 0.08));
    float t2 = gnoise(puv * 40.0 - float2(time * 0.06, time * 0.10));
    float t3 = noise(puv * 55.0 + float2(-time * 0.09, time * 0.05));

    return t1 * 0.5 + t2 * 0.3 + t3 * 0.2;
}

vertex VertexOut waterVertex(uint vid [[vertex_id]],
                             constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    float2 pos = vertices[vid];
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    out.uv.y = 1.0 - out.uv.y;
    return out;
}

fragment float4 waterFragment(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float time = u.time;

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

    float h = waveHeight(uv, time);

    for (int i = 0; i < u.rippleCount && i < 8; i++) {
        h += rippleHeight(uv, u.ripples[i], time);
    }

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

    float tex = surfaceTexture(uv, time);
    float texL = surfaceTexture(uv - float2(eps, 0.0), time);
    float texR = surfaceTexture(uv + float2(eps, 0.0), time);
    float texD = surfaceTexture(uv - float2(0.0, eps), time);
    float texU = surfaceTexture(uv + float2(0.0, eps), time);
    float2 texNormal = float2(texL - texR, texD - texU) / (2.0 * eps);

    normal += texNormal * 0.25;

    float2 lightDir = normalize(float2(0.35, -0.55));
    float specular = dot(normalize(normal), lightDir);
    specular = pow(clamp(specular, 0.0, 1.0), 20.0) * 0.22;

    float2 lightDir2 = normalize(float2(-0.4, -0.35));
    float spec2 = dot(normalize(normal), lightDir2);
    spec2 = pow(clamp(spec2, 0.0, 1.0), 10.0) * 0.08;

    float spec3 = dot(normalize(normal), normalize(float2(0.0, -1.0)));
    spec3 = pow(clamp(spec3, 0.0, 1.0), 4.0) * 0.04;

    float totalSpec = specular + spec2 + spec3;

    float c = caustics(uv + normal * 0.4, time);
    c *= 0.12;

    float3 deepColor    = float3(0.03, 0.12, 0.32);
    float3 shallowColor = float3(0.06, 0.20, 0.40);
    float3 tileHintColor = float3(0.04, 0.15, 0.35);

    float2 poolCenter = float2(0.65, 0.82);
    float distFromCenter = length(uv - poolCenter);
    float depthFactor = smoothstep(0.0, 0.22, distFromCenter);
    float3 baseColor = mix(deepColor, shallowColor, depthFactor);

    float colorNoise = fbm(uv * 5.0 + float2(time * 0.02, -time * 0.01));
    baseColor = mix(baseColor, tileHintColor, colorNoise * 0.25);

    baseColor += float3(0.006, 0.014, 0.025) * (tex - 0.5);
    baseColor += float3(0.008, 0.02, 0.03) * h * 6.0;

    float3 causticColor = float3(0.10, 0.25, 0.45) * c;
    float3 specColor = float3(0.85, 0.92, 1.0) * totalSpec;

    float3 finalColor = baseColor + causticColor + specColor;

    float alpha = 0.38;
    alpha += totalSpec * 0.35;
    alpha += h * 0.6;
    alpha += c * 0.2;
    alpha += (tex - 0.5) * 0.06;

    alpha = clamp(alpha, 0.0, 0.65);
    alpha *= edgeFade;

    return float4(finalColor, alpha);
}
"""

// MARK: - Renderer

@MainActor
final class WaterRenderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer

    private var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    private var uniforms = WaterUniforms()
    private var ripples: [ActiveRipple] = []
    private let maxRipples = 8
    private let rippleLifetime: Float = 4.0

    init?(mtkView: MTKView) {
        guard let device = mtkView.device,
              let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue

        // Compile shader from source string at runtime
        guard let library = try? device.makeLibrary(source: waterShaderSource, options: nil),
              let vertexFn = library.makeFunction(name: "waterVertex"),
              let fragmentFn = library.makeFunction(name: "waterFragment")
        else { return nil }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFn
        desc.fragmentFunction = fragmentFn
        desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let pipeline = try? device.makeRenderPipelineState(descriptor: desc)
        else { return nil }
        self.pipelineState = pipeline

        let quadVertices: [SIMD2<Float>] = [
            SIMD2(-1, -1), SIMD2( 1, -1), SIMD2(-1,  1),
            SIMD2(-1,  1), SIMD2( 1, -1), SIMD2( 1,  1)
        ]
        guard let vb = device.makeBuffer(bytes: quadVertices,
                                          length: MemoryLayout<SIMD2<Float>>.stride * 6,
                                          options: .storageModeShared)
        else { return nil }
        self.vertexBuffer = vb

        super.init()
    }

    func addRipple(at pos: SIMD2<Float>) {
        let currentTime = Float(CFAbsoluteTimeGetCurrent() - startTime)
        let seed = Float.random(in: 1.0...1000.0)
        ripples.append(ActiveRipple(position: pos, birthTime: currentTime, seed: seed))
        if ripples.count > maxRipples {
            ripples.removeFirst()
        }
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated {
            uniforms.resolution = SIMD2<Float>(Float(size.width), Float(size.height))
        }
    }

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            drawFrame(in: view)
        }
    }

    private func drawFrame(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let passDesc = view.currentRenderPassDescriptor
        else { return }

        let currentTime = Float(CFAbsoluteTimeGetCurrent() - startTime)

        ripples.removeAll { currentTime - $0.birthTime > rippleLifetime }

        uniforms.time = currentTime
        uniforms.rippleCount = Int32(ripples.count)

        var r = uniforms.ripples
        withUnsafeMutablePointer(to: &r) { ptr in
            let base = UnsafeMutableRawPointer(ptr)
                .assumingMemoryBound(to: SIMD4<Float>.self)
            for i in 0..<8 {
                if i < ripples.count {
                    base[i] = SIMD4<Float>(ripples[i].position.x,
                                           ripples[i].position.y,
                                           ripples[i].birthTime,
                                           ripples[i].seed)
                } else {
                    base[i] = .zero
                }
            }
        }
        uniforms.ripples = r

        passDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        passDesc.colorAttachments[0].loadAction = .clear

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDesc)
        else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&uniforms,
                                  length: MemoryLayout<WaterUniforms>.stride,
                                  index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - SwiftUI Wrapper

struct WaterMetalView: UIViewRepresentable {
    let bridge: WaterRendererBridge
    var isActive: Bool
    var reduceMotion: Bool

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.isOpaque = false
        mtkView.backgroundColor = .clear
        mtkView.preferredFramesPerSecond = 30
        mtkView.layer.isOpaque = false

        if let renderer = WaterRenderer(mtkView: mtkView) {
            mtkView.delegate = renderer
            bridge.renderer = renderer
            context.coordinator.renderer = renderer
            renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        }

        mtkView.isPaused = reduceMotion || !isActive
        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        mtkView.isPaused = reduceMotion || !isActive
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var renderer: WaterRenderer?
    }
}
