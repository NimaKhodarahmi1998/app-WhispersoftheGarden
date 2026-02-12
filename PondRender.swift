//
//  SwiftUIView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 12/02/26.
//

import Metal
import MetalKit

final class PondRenderer: NSObject, MTKViewDelegate {
    struct Uniforms { var time: Float; var aspect: Float }

    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private var startTime = CACurrentMediaTime()

    private let vertices: [Float] = [
        -1, -1,  0,  1,
         1, -1,  1,  1,
        -1,  1,  0,  0,
         1, -1,  1,  1,
         1,  1,  1,  0,
        -1,  1,  0,  0,
    ]

    init(device: MTLDevice, view: MTKView) {
        self.device = device
        self.queue = device.makeCommandQueue()!

        let library = try! device.makeLibrary(source: PondShaders.mslSource, options: nil)
        let vfn = library.makeFunction(name: "pond_vertex")!
        let ffn = library.makeFunction(name: "pond_fragment")!

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vfn
        desc.fragmentFunction = ffn
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        self.pipeline = try! device.makeRenderPipelineState(descriptor: desc)

        self.vertexBuffer = device.makeBuffer(bytes: vertices,
                                              length: vertices.count * MemoryLayout<Float>.size,
                                              options: .storageModeShared)!
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: rpd) else { return }

        let t = Float(CACurrentMediaTime() - startTime)
        let aspect = Float(view.drawableSize.width / max(1, view.drawableSize.height))
        var u = Uniforms(time: t, aspect: aspect)

        enc.setRenderPipelineState(pipeline)
        enc.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        enc.setFragmentBytes(&u, length: MemoryLayout<Uniforms>.size, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        enc.endEncoding()

        cmd.present(drawable)
        cmd.commit()
    }
}
