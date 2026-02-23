//
//  WaterMetalView.swift
//  WhispersoftheGardenApp
//
//  MTKView-based water renderer wrapped for SwiftUI (iOS 16+).
//  Renders the animated water surface shader inside the garden pool.
//

import SwiftUI
import MetalKit

// MARK: - Uniforms (must match WaterShader.metal layout)

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
    var position: SIMD2<Float>   // normalized coords
    var birthTime: Float         // in shader-time seconds
}

// MARK: - Bridge (SwiftUI → Metal communication)

final class WaterRendererBridge: @unchecked Sendable {
    fileprivate var renderer: WaterRenderer?

    func addRipple(at normalizedPoint: CGPoint) {
        renderer?.addRipple(at: SIMD2<Float>(Float(normalizedPoint.x),
                                              Float(normalizedPoint.y)))
    }
}

// MARK: - Renderer

final class WaterRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer

    private var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    private var uniforms = WaterUniforms()
    private var ripples: [ActiveRipple] = []
    private let maxRipples = 8
    private let rippleLifetime: Float = 3.5

    init?(mtkView: MTKView) {
        guard let device = mtkView.device,
              let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue

        // Load shaders
        guard let library = device.makeDefaultLibrary(),
              let vertexFn = library.makeFunction(name: "waterVertex"),
              let fragmentFn = library.makeFunction(name: "waterFragment")
        else { return nil }

        // Pipeline
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFn
        desc.fragmentFunction = fragmentFn
        desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        // Alpha blending for transparent overlay
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let pipeline = try? device.makeRenderPipelineState(descriptor: desc)
        else { return nil }
        self.pipelineState = pipeline

        // Fullscreen quad (2 triangles, clip space)
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
        ripples.append(ActiveRipple(position: pos, birthTime: currentTime))
        if ripples.count > maxRipples {
            ripples.removeFirst()
        }
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.resolution = SIMD2<Float>(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let passDesc = view.currentRenderPassDescriptor
        else { return }

        let currentTime = Float(CFAbsoluteTimeGetCurrent() - startTime)

        // Expire old ripples
        ripples.removeAll { currentTime - $0.birthTime > rippleLifetime }

        // Update uniforms
        uniforms.time = currentTime
        uniforms.rippleCount = Int32(ripples.count)

        // Copy ripple data into the fixed-size tuple
        var r = uniforms.ripples
        withUnsafeMutablePointer(to: &r) { ptr in
            let base = UnsafeMutableRawPointer(ptr)
                .assumingMemoryBound(to: SIMD4<Float>.self)
            for i in 0..<8 {
                if i < ripples.count {
                    base[i] = SIMD4<Float>(ripples[i].position.x,
                                           ripples[i].position.y,
                                           ripples[i].birthTime, 0)
                } else {
                    base[i] = .zero
                }
            }
        }
        uniforms.ripples = r

        // Transparent clear color
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
            // Trigger initial size
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
        // Strong reference keeps the renderer alive
        var renderer: WaterRenderer?
    }
}
