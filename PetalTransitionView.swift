//
//  PetalTransitionView.swift
//  WhispersoftheGardenApp
//
//  Petal wave transition. Petals sweep across the screen while the views
//  cross-dissolve underneath. Wind direction controls whether petals blow
//  right-to-left or left-to-right.
//

import SwiftUI

enum PetalWindDirection {
    case original      // radial sweep (Landing ↔ Garden)
    case rightToLeft   // Garden → Library
    case leftToRight   // Library → Garden
}

struct PetalTransitionView: View {
    var wind: PetalWindDirection = .original
    var reduceMotion: Bool = false

    @State private var startTime = Date()
    @State private var fadeOpacity: Double = 0

    private let duration: TimeInterval = 2.4
    private let petalCount = 180

    var body: some View {
        if reduceMotion {
            Color(red: 0, green: 0.125, blue: 0.28)
                .opacity(fadeOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(true)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.25)) {
                        fadeOpacity = 0.72
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            fadeOpacity = 0
                        }
                    }
                }
        } else {
            GeometryReader { geo in
                TimelineView(.animation) { timeline in
                    Canvas(rendersAsynchronously: false) { context, size in
                        let elapsed = min(
                            max(0, timeline.date.timeIntervalSince(startTime)),
                            duration
                        )
                        let progress = elapsed / duration

                        drawBackground(in: &context, size: size, progress: progress)
                        drawPetals(in: &context, size: size, progress: progress)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .allowsHitTesting(true)
            .ignoresSafeArea()
        }
    }

    // MARK: - Background

    private func drawBackground(
        in context: inout GraphicsContext, size: CGSize, progress: Double
    ) {
        let peakStart = 0.25
        let peakEnd   = 0.42
        let fadeEnd   = 0.68

        let opacity: Double
        if progress < peakStart {
            let t = progress / peakStart
            opacity = t * t * 0.72
        } else if progress < peakEnd {
            opacity = 0.72
        } else if progress < fadeEnd {
            let t = (progress - peakEnd) / (fadeEnd - peakEnd)
            opacity = 0.72 * (1.0 - t * t)
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
        let path = ParticleData.petalPath(size: 1)

        for i in 0..<petalCount {
            drawSinglePetal(
                index: i, progress: progress,
                context: &context, size: size, path: path
            )
        }
    }

    private func drawSinglePetal(
        index: Int, progress: Double,
        context: inout GraphicsContext, size: CGSize, path: Path
    ) {
        let i = Double(index)

        // Deterministic pseudo-random values per petal
        let r1 = fract(sin(i * 127.1 + 311.7) * 43758.5453)
        let r2 = fract(sin(i * 269.5 + 183.3) * 43758.5453)
        let r3 = fract(sin(i * 419.2 + 571.1) * 43758.5453)
        let r4 = fract(sin(i * 631.8 + 223.9) * 43758.5453)
        let r5 = fract(sin(i * 157.3 + 493.1) * 43758.5453)

        // Stagger
        let stagger = r1 * 0.12
        let localP = max(0, min(1, (progress - stagger) / (1.0 - stagger)))
        guard localP > 0 else { return }

        // --- Size ---
        let baseSize = CGFloat(30 + r2 * 28)
        let sizeFactor: CGFloat
        if localP < 0.20 {
            let t = CGFloat(localP / 0.20)
            sizeFactor = t * (2.0 - t)
        } else if localP < 0.55 {
            sizeFactor = 1.0
        } else {
            let t = CGFloat((localP - 0.55) / 0.45)
            sizeFactor = max(0, 1.0 - t * t)
        }
        let petalSize = baseSize * sizeFactor
        guard petalSize > 1 else { return }

        // --- Position ---
        let w = Double(size.width)
        let h = Double(size.height)
        let diag = sqrt(w * w + h * h)

        let startX: Double, startY: Double
        let midX: Double, midY: Double
        let exitX: Double, exitY: Double

        midX = (0.08 + r2 * 0.84) * w
        midY = (0.05 + r4 * 0.9) * h

        switch wind {
        case .original:
            // Radial sweep from edges (original behavior)
            let entryAngle = (.pi * 0.6) + (r3 - 0.5) * .pi * 0.7
            startX = w * 0.5 + cos(entryAngle) * diag * 0.7
            startY = h * 0.5 + sin(entryAngle) * diag * 0.7
            exitX = midX + (r5 - 0.3) * 180
            exitY = h + 60 + r3 * 100

        case .rightToLeft:
            startX = w + 40 + r3 * 120
            startY = -30 + r4 * (h + 60)
            exitX = -60 - r5 * 100
            exitY = midY + 40 + r3 * 80

        case .leftToRight:
            startX = -40 - r3 * 120
            startY = -30 + r4 * (h + 60)
            exitX = w + 60 + r5 * 100
            exitY = midY + 40 + r3 * 80
        }

        let x: Double, y: Double
        if localP < 0.40 {
            let t = localP / 0.40
            let ease = 1.0 - (1.0 - t) * (1.0 - t)
            x = startX + (midX - startX) * ease
            y = startY + (midY - startY) * ease
        } else {
            let t = (localP - 0.40) / 0.60
            let ease = t * t * t
            x = midX + (exitX - midX) * ease
            y = midY + (exitY - midY) * ease
        }

        let windDir: Double = wind == .leftToRight ? 1.0 : -1.0
        let swayX = sin(localP * (wind == .original ? 6.0 : 5.0) + i * 0.8) * (wind == .original ? 12.0 : 8.0) * windDir
        let swayY = cos(localP * 4.0 + i * 1.1) * (wind == .original ? 6.0 : 14.0)

        // --- Opacity ---
        let opacity: Double
        if localP < 0.15 {
            opacity = localP / 0.15
        } else if localP < 0.55 {
            opacity = 1.0
        } else {
            let t = (localP - 0.55) / 0.45
            opacity = max(0, 1.0 - t * t)
        }
        guard opacity > 0.01 else { return }

        // --- Rotation & tumble ---
        let spinDir = wind == .original ? 1.0 : windDir
        let rotation = CGFloat(i * 0.7 + localP * .pi * 2.5 * spinDir)
        let tumble = cos(CGFloat(localP) * 6 + CGFloat(i) * 0.9)
        let faceAmount = abs(tumble)

        // --- Color ---
        let colors: [(r: Double, g: Double, b: Double)] = [
            (0.92, 0.35, 0.42),
            (0.95, 0.50, 0.55),
            (0.82, 0.25, 0.33),
            (0.88, 0.45, 0.50),
            (0.90, 0.40, 0.48),
        ]
        let c = colors[index % colors.count]

        // --- Draw ---
        var ctx = context
        ctx.translateBy(x: CGFloat(x + swayX), y: CGFloat(y + swayY))
        ctx.rotate(by: .radians(rotation))
        ctx.scaleBy(x: petalSize, y: petalSize)
        ctx.scaleBy(x: tumble, y: 1.0)
        ctx.opacity = opacity * (0.6 + Double(faceAmount) * 0.4)

        ctx.fill(path, with: .color(Color(red: c.r, green: c.g, blue: c.b)))

        if faceAmount > 0.5 {
            var hlCtx = ctx
            hlCtx.opacity = Double(faceAmount - 0.5) * 0.3
            hlCtx.fill(path, with: .color(.white))
        }
    }

    // MARK: - Helpers

    private func fract(_ x: Double) -> Double {
        x - floor(x)
    }
}
