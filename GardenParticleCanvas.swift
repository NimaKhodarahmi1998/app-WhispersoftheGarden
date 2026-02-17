//
//  GardenParticleCanvas.swift
//  WhispersoftheGardenApp
//
//  Canvas-based particle system: golden pollen motes + rose petals
//  Renders at 60fps via TimelineView + Canvas (single draw pass, no blur/shadow)
//

import SwiftUI

// MARK: - Particle Types

struct PollenMote {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    var drift: CGFloat
    var phase: CGFloat
    var warmth: CGFloat      // 0 = pale gold, 1 = deep amber
}

struct PetalParticle {
    var x: CGFloat
    var y: CGFloat
    var rotation: CGFloat
    var rotationSpeed: CGFloat
    var tumblePhase: CGFloat   // fakes 3D flip via scaleX
    var tumbleSpeed: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var fallSpeed: CGFloat
    var drift: CGFloat
    var swayPhase: CGFloat
    var swayAmplitude: CGFloat
    var liftPhase: CGFloat     // occasional updraft
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
}

// MARK: - Particle System

final class ParticleData: ObservableObject, @unchecked Sendable {

    private var pollen: [PollenMote] = []
    private var petals: [PetalParticle] = []
    private var lastTime: TimeInterval = 0
    private var initialized = false
    private var handledBursts = 0

    // MARK: Setup

    private func setup(size: CGSize) {
        guard !initialized else { return }
        initialized = true

        for _ in 0..<40 {
            pollen.append(Self.makePollen(in: size, randomY: true))
        }
        for _ in 0..<3 {
            petals.append(Self.makePetal(in: size, randomY: true))
        }
    }

    // MARK: Burst Handling

    func handleBursts(requested: Int, size: CGSize) {
        let newBursts = requested - handledBursts
        guard newBursts > 0 else { return }
        handledBursts = requested

        for _ in 0..<min(newBursts * 2, 8) {
            petals.append(Self.makePetal(in: size))
        }
        if petals.count > 12 {
            petals.removeFirst(petals.count - 12)
        }
    }

    // MARK: Update

    func update(time: TimeInterval, size: CGSize) {
        let dt = lastTime == 0 ? 0.016 : min(time - lastTime, 0.05)
        lastTime = time

        if !initialized { setup(size: size) }

        // --- Pollen ---
        for i in pollen.indices {
            let sway = CGFloat(sin(time * 0.7 + Double(pollen[i].phase))) * 15.0
            pollen[i].y += pollen[i].speed * CGFloat(dt)
            pollen[i].x += (pollen[i].drift + sway) * CGFloat(dt)

            // gentle opacity pulse
            let pulse = CGFloat(sin(time * 1.5 + Double(pollen[i].phase) * 2.0))
            pollen[i].opacity = (0.35 + pollen[i].warmth * 0.15) + pulse * 0.12

            if pollen[i].y > size.height + 30 {
                pollen[i] = Self.makePollen(in: size, randomY: false)
            }
            if pollen[i].x < -30 { pollen[i].x = size.width + 20 }
            if pollen[i].x > size.width + 30 { pollen[i].x = -20 }
        }

        // --- Petals ---
        for i in petals.indices {
            let sway = CGFloat(sin(time * 0.5 + Double(petals[i].swayPhase)))
                * petals[i].swayAmplitude
            let lift = CGFloat(sin(time * 0.25 + Double(petals[i].liftPhase)))
            // occasional updraft when lift > 0.6
            let liftForce: CGFloat = lift > 0.6 ? -20.0 * (lift - 0.6) / 0.4 : 0

            petals[i].y += (petals[i].fallSpeed + liftForce) * CGFloat(dt)
            petals[i].x += (petals[i].drift + sway) * CGFloat(dt)
            petals[i].rotation += petals[i].rotationSpeed * CGFloat(dt)
            petals[i].tumblePhase += petals[i].tumbleSpeed * CGFloat(dt)

            if petals[i].y > size.height + 50 {
                petals[i] = Self.makePetal(in: size)
            }
            if petals[i].x < -50 { petals[i].x = size.width + 30 }
            if petals[i].x > size.width + 50 { petals[i].x = -30 }
        }
    }

    // MARK: Render

    func render(in context: inout GraphicsContext, size: CGSize) {

        // --- Pollen motes (warm golden glow) ---
        for mote in pollen {
            var ctx = context
            ctx.translateBy(x: mote.x, y: mote.y)

            let r = mote.size
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)

            let color = Color(
                red: 1.0,
                green: 0.92 - Double(mote.warmth) * 0.1,
                blue: 0.65 - Double(mote.warmth) * 0.2
            )

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

        // --- Rose petals (bezier shape + 3D tumble) ---
        let path = Self.petalPath(size: 1) // unit-size, scaled per petal

        for petal in petals {
            var ctx = context
            ctx.translateBy(x: petal.x, y: petal.y)
            ctx.rotate(by: .radians(petal.rotation))
            ctx.scaleBy(x: petal.size, y: petal.size)

            // fake 3D tumble: compress horizontally
            let tumble = cos(petal.tumblePhase)
            ctx.scaleBy(x: tumble, y: 1.0)

            let faceAmount = abs(tumble)
            ctx.opacity = Double(petal.opacity) * (0.5 + Double(faceAmount) * 0.5)

            let color = Color(
                red: Double(petal.r),
                green: Double(petal.g),
                blue: Double(petal.b)
            )
            ctx.fill(path, with: .color(color))

            // soft highlight when face-on
            if faceAmount > 0.5 {
                var hlCtx = ctx
                hlCtx.opacity = Double(faceAmount - 0.5) * 0.35
                hlCtx.fill(path, with: .color(.white))
            }
        }
    }

    // MARK: - Factory Methods

    private static func makePollen(in size: CGSize, randomY: Bool) -> PollenMote {
        PollenMote(
            x: .random(in: 0...size.width),
            y: randomY ? .random(in: 0...size.height) : .random(in: -40...(-5)),
            size: .random(in: 2.5...5.5),
            opacity: .random(in: 0.3...0.55),
            speed: .random(in: 12...28),
            drift: .random(in: -8...8),
            phase: .random(in: 0...(2 * .pi)),
            warmth: .random(in: 0...1)
        )
    }

    private static func makePetal(in size: CGSize, randomY: Bool = false) -> PetalParticle {
        let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
            (0.92, 0.35, 0.42),   // rose
            (0.95, 0.50, 0.55),   // soft pink
            (0.82, 0.25, 0.33),   // crimson
            (0.88, 0.45, 0.50),   // blush
        ]
        let c = colors.randomElement()!

        return PetalParticle(
            x: .random(in: 0...size.width),
            y: randomY ? .random(in: 0...size.height) : .random(in: -60...(-10)),
            rotation: .random(in: 0...(2 * .pi)),
            rotationSpeed: .random(in: 0.3...1.2) * (Bool.random() ? 1 : -1),
            tumblePhase: .random(in: 0...(2 * .pi)),
            tumbleSpeed: .random(in: 1.5...3.0),
            size: .random(in: 10...18),
            opacity: .random(in: 0.7...0.95),
            fallSpeed: .random(in: 25...45),
            drift: .random(in: -5...5),
            swayPhase: .random(in: 0...(2 * .pi)),
            swayAmplitude: .random(in: 15...30),
            liftPhase: .random(in: 0...(2 * .pi)),
            r: c.r, g: c.g, b: c.b
        )
    }

    // Petal shape: pointed at stem, rounded at top (unit size, centered at origin)
    static func petalPath(size: CGFloat) -> Path {
        let w = size * 0.35
        let h = size * 0.55

        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addCurve(
            to: CGPoint(x: 0, y: -h),
            control1: CGPoint(x: w * 1.8, y: h * 0.2),
            control2: CGPoint(x: w * 1.2, y: -h * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: h),
            control1: CGPoint(x: -w * 1.2, y: -h * 0.8),
            control2: CGPoint(x: -w * 1.8, y: h * 0.2)
        )
        return path
    }
}

// MARK: - Canvas View

struct GardenParticleCanvas: View {
    let petalBurst: Int
    var reduceMotion: Bool = false

    @StateObject private var system = ParticleData()

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation) { timeline in
                Canvas(rendersAsynchronously: false) { context, size in
                    system.update(
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        size: size
                    )
                    system.handleBursts(requested: petalBurst, size: size)
                    system.render(in: &context, size: size)
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}
