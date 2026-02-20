//
//  LibraryDustCanvas.swift
//  WhispersoftheGardenApp
//
//  Floating dust-in-lamplight particle system for the Library.
//  Warm amber motes drifting slowly — subtle atmospheric layer.
//

import SwiftUI

// MARK: - Dust Mote

private struct DustMote {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var driftX: CGFloat
    var driftY: CGFloat
    var phase: CGFloat
}

// MARK: - Particle Data

private final class DustParticleData: ObservableObject, @unchecked Sendable {

    private var motes: [DustMote] = []
    private var lastTime: TimeInterval = 0
    private var initialized = false

    private static func makeMote(in size: CGSize, randomPosition: Bool) -> DustMote {
        DustMote(
            x: .random(in: 0...size.width),
            y: randomPosition ? .random(in: 0...size.height) : .random(in: -40...(-5)),
            size: .random(in: 1.5...3.5),
            opacity: .random(in: 0.08...0.20),
            driftX: .random(in: -6...6),
            driftY: .random(in: 4...12),
            phase: .random(in: 0...(2 * .pi))
        )
    }

    func update(time: TimeInterval, size: CGSize) {
        let dt = lastTime == 0 ? 0.016 : min(time - lastTime, 0.05)
        lastTime = time

        if !initialized {
            initialized = true
            for _ in 0..<18 {
                motes.append(Self.makeMote(in: size, randomPosition: true))
            }
        }

        for i in motes.indices {
            let sway = CGFloat(sin(time * 0.4 + Double(motes[i].phase))) * 8.0
            motes[i].x += (motes[i].driftX + sway) * CGFloat(dt)
            motes[i].y += motes[i].driftY * CGFloat(dt)

            // gentle opacity pulse
            let pulse = CGFloat(sin(time * 0.8 + Double(motes[i].phase) * 1.5))
            motes[i].opacity = 0.12 + pulse * 0.06

            // wrap around edges
            if motes[i].y > size.height + 20 {
                motes[i] = Self.makeMote(in: size, randomPosition: false)
            }
            if motes[i].x < -20 { motes[i].x = size.width + 10 }
            if motes[i].x > size.width + 20 { motes[i].x = -10 }
        }
    }

    func render(in context: inout GraphicsContext, size: CGSize, isDark: Bool) {
        let color = isDark
            ? Color(red: 1.0, green: 0.90, blue: 0.65)
            : Color(red: 0.72, green: 0.58, blue: 0.32)

        for mote in motes {
            var ctx = context
            ctx.translateBy(x: mote.x, y: mote.y)

            let r = mote.size
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)

            ctx.fill(
                Circle().path(in: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        color.opacity(Double(mote.opacity)),
                        color.opacity(Double(mote.opacity) * 0.3),
                        .clear
                    ]),
                    center: .zero,
                    startRadius: 0,
                    endRadius: r
                )
            )
        }
    }
}

// MARK: - Canvas View

struct LibraryDustCanvas: View {
    var reduceMotion: Bool = false
    var isActive: Bool = true
    var isDark: Bool = true

    @StateObject private var system = DustParticleData()

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation(paused: !isActive)) { timeline in
                Canvas(rendersAsynchronously: false) { context, size in
                    guard isActive else { return }
                    system.update(
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        size: size
                    )
                    system.render(in: &context, size: size, isDark: isDark)
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}
