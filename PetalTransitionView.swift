//
//  PetalTransitionView.swift
//  WhispersoftheGardenApp
//
//  A gust of rose petals blown from one side — they stream from a
//  single point, fan across the screen, and exit off the far edge.
//

import SwiftUI

enum PetalWindDirection {
    case original      // blown from top centre (Landing → Garden)
    case rightToLeft   // blown from the right  (Garden → Library)
    case leftToRight   // blown from the left   (Library → Garden)
}

// MARK: - Per-Petal Constants

private struct PetalSeed {
    let r1, r2, r3, r4, r5, r6, r7, r8: Double
    let stagger: Double
    let coneAngle: Double
    let travelSpeed: Double
    let originSpread: Double
    let originAngle: Double
    let depth: Double
    let baseSize: CGFloat
    let baseOpacity: Double
    let swayFreq: Double
    let swayAmp: Double
    let swayPhase: Double
    let spinSpeed: Double
    let tumbleSpeed: CGFloat
    let phaseRot: Double
    let phaseTumble: CGFloat
    let colorR, colorG, colorB: Double

    init(index: Int) {
        let i = Double(index)

        func hash(_ a: Double, _ b: Double) -> Double {
            let v = sin(a + b) * 43758.5453
            return v - floor(v)
        }

        r1 = hash(i * 127.1, 311.7)
        r2 = hash(i * 269.5, 183.3)
        r3 = hash(i * 419.2, 571.1)
        r4 = hash(i * 631.8, 223.9)
        r5 = hash(i * 157.3, 493.1)
        r6 = hash(i * 743.6, 109.4)
        r7 = hash(i * 853.1, 427.3)
        r8 = hash(i * 317.9, 691.2)

        // Stream stagger — petals flow out as a gust
        stagger = r1 * 0.18

        // Cone spread: ±40° from base wind direction
        coneAngle = (r5 - 0.5) * 1.4

        // Travel speed: enough to cross the screen and exit
        travelSpeed = 0.6 + pow(r6, 0.6) * 1.4

        // Origin spread: tight cluster at entry point
        originSpread = hash(i * 503.7, 347.1) * 65.0
        originAngle = hash(i * 661.3, 211.9) * 2.0 * .pi

        // Depth → size & opacity
        depth = r2
        let sizeScale = 0.5 + depth * 0.85
        baseSize = CGFloat((16 + r7 * 24) * sizeScale)
        baseOpacity = 0.35 + depth * 0.50

        // Sway (perpendicular flutter)
        swayFreq = 1.0 + r8 * 3.5
        swayAmp = 15.0 + hash(i * 547.3, 283.7) * 40.0
        swayPhase = hash(i * 193.7, 823.1) * 2.0 * .pi

        // Spin & tumble
        spinSpeed = 0.5 + hash(i * 911.3, 173.7) * 1.6
        tumbleSpeed = CGFloat(1.5 + hash(i * 617.3, 359.1) * 3.0)
        phaseRot = hash(i * 241.9, 587.3) * 2.0 * .pi
        phaseTumble = CGFloat(hash(i * 389.7, 953.2) * 2.0 * .pi)

        // Color — rose palette
        let colors: [(Double, Double, Double)] = [
            (0.92, 0.35, 0.42), (0.95, 0.50, 0.55),
            (0.82, 0.25, 0.33), (0.88, 0.45, 0.50),
            (0.90, 0.40, 0.48),
        ]
        let c = colors[index % 5]
        colorR = c.0; colorG = c.1; colorB = c.2
    }
}

// MARK: - Transition View

struct PetalTransitionView: View {
    var wind: PetalWindDirection = .original
    var reduceMotion: Bool = false
    var isActive: Bool = false

    @State private var startTime = Date()
    @State private var fadeOpacity: Double = 0

    private let duration: TimeInterval = 1.5
    private static let seeds: [PetalSeed] = (0..<320).map { PetalSeed(index: $0) }
    private static let unitPath: Path = ParticleData.petalPath(size: 1)

    var body: some View {
        ZStack {
            // Reduce-motion overlay
            if reduceMotion {
                Color(red: 0, green: 0.125, blue: 0.28)
                    .opacity(isActive ? fadeOpacity : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(isActive)
            }

            // Full petal canvas — always in the tree, paused when inactive
            if !reduceMotion {
                GeometryReader { geo in
                    TimelineView(.animation(paused: !isActive)) { timeline in
                        Canvas(rendersAsynchronously: true) { context, size in
                            guard isActive else { return }
                            let elapsed = Swift.min(
                                Swift.max(0, timeline.date.timeIntervalSince(startTime)),
                                duration
                            )
                            let progress = elapsed / duration

                            drawBackground(in: &context, size: size, progress: progress)
                            drawPetals(in: &context, size: size, progress: progress)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .allowsHitTesting(isActive)
                .ignoresSafeArea()
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startTime = Date()
                if reduceMotion {
                    fadeOpacity = 0
                    withAnimation(.easeIn(duration: 0.25)) {
                        fadeOpacity = 0.72
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            fadeOpacity = 0
                        }
                    }
                }
            }
        }
    }

    // MARK: - Background

    private func drawBackground(
        in context: inout GraphicsContext, size: CGSize, progress: Double
    ) {
        let peakStart = 0.10
        let peakEnd   = 0.35
        let fadeEnd   = 0.55

        let opacity: Double
        if progress < peakStart {
            let t = progress / peakStart
            opacity = t * t * 0.30
        } else if progress < peakEnd {
            opacity = 0.30
        } else if progress < fadeEnd {
            let t = (progress - peakEnd) / (fadeEnd - peakEnd)
            opacity = 0.30 * (1.0 - t * t)
        } else {
            opacity = 0
        }

        guard opacity > 0.001 else { return }

        context.fill(
            Rectangle().path(in: CGRect(origin: .zero, size: size)),
            with: .color(Color(red: 0, green: 0.125, blue: 0.28).opacity(opacity))
        )
    }

    // MARK: - Petals

    private func drawPetals(
        in context: inout GraphicsContext, size: CGSize, progress: Double
    ) {
        let path = Self.unitPath

        for seed in Self.seeds {
            drawPetal(
                seed: seed, progress: progress,
                context: &context, size: size, path: path
            )
        }
    }

    private func drawPetal(
        seed: PetalSeed, progress: Double,
        context: inout GraphicsContext, size: CGSize, path: Path
    ) {
        let localP = Swift.max(0, Swift.min(1, (progress - seed.stagger) / (1.0 - seed.stagger)))
        guard localP > 0 else { return }

        let w = Double(size.width)
        let h = Double(size.height)
        let diagonal = sqrt(w * w + h * h)

        // Origin point and base direction based on wind
        let originX: Double
        let originY: Double
        let baseAngle: Double

        switch wind {
        case .original:
            originX = w * 0.5
            originY = -20
            baseAngle = Double.pi * 0.5  // downward
        case .rightToLeft:
            originX = w + 20
            originY = h * 0.45
            baseAngle = Double.pi  // leftward
        case .leftToRight:
            originX = -20
            originY = h * 0.45
            baseAngle = 0          // rightward
        }

        // Start from origin with small spread
        let startX = originX + cos(seed.originAngle) * seed.originSpread
        let startY = originY + sin(seed.originAngle) * seed.originSpread

        // Direction within the cone
        let angle = baseAngle + seed.coneAngle

        // Travel: slight acceleration, enough to cross and exit
        let easedP = localP * (0.7 + 0.3 * localP)
        let distance = diagonal * 0.80 * seed.travelSpeed * easedP

        var x = startX + cos(angle) * distance
        var y = startY + sin(angle) * distance

        // Sway perpendicular to travel direction
        let perpAngle = angle + .pi / 2
        let sway = sin(localP * seed.swayFreq * .pi * 2.0 + seed.swayPhase) * seed.swayAmp
        x += cos(perpAngle) * sway
        y += sin(perpAngle) * sway

        // Opacity: quick fade in, safety fade at very end
        let fadeIn = Swift.min(1.0, localP / 0.06)
        let fadeOut = Swift.min(1.0, (1.0 - localP) / 0.12)
        let fade = fadeIn * fadeOut * seed.baseOpacity
        guard fade > 0.01 else { return }

        // Rotation & tumble
        let rotation = CGFloat(seed.phaseRot + localP * .pi * 2.0 * seed.spinSpeed)
        let tumble = cos(CGFloat(localP) * .pi * 2.0 * seed.tumbleSpeed + seed.phaseTumble)
        let faceAmount = abs(tumble)

        // Draw
        var ctx = context
        ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
        ctx.rotate(by: .radians(rotation))
        ctx.scaleBy(x: seed.baseSize, y: seed.baseSize)
        ctx.scaleBy(x: tumble, y: 1.0)
        ctx.opacity = fade * (0.6 + Double(faceAmount) * 0.4)

        ctx.fill(path, with: .color(Color(red: seed.colorR, green: seed.colorG, blue: seed.colorB)))

        if faceAmount > 0.5 {
            var hlCtx = ctx
            hlCtx.opacity = Double(faceAmount - 0.5) * 0.3
            hlCtx.fill(path, with: .color(.white))
        }
    }
}
