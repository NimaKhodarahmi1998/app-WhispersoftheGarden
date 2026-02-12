//
//  SwiftUIView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 12/02/26.
//

import SwiftUI
import MetalKit

@MainActor
struct PondView: UIViewRepresentable {

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)

        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var renderer: PondRenderer?

        func attach(to view: MTKView) {
            guard let device = view.device else { return }
            renderer = PondRenderer(device: device, view: view)
            view.delegate = renderer
        }
    }
}
