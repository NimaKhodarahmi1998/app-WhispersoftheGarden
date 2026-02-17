//
//  PetalTransitionView.swift
//  WhispersoftheGardenApp
//
//  Petal wave transition. Petals sweep across the screen while the views
//  cross-dissolve underneath. Wind direction controls petal flow.
//

import SwiftUI

enum PetalWindDirection {
    case original      // top-to-bottom fall (Landing → Garden)
    case rightToLeft   // Garden → Library
    case leftToRight   // Library → Garden
}

// MARK: - Precomputed Per-Petal Constants

private struct PetalSeed {
    let r2, r3, r4, r5, r6: Double
    let stagger: Double
    let baseSize: CGFloat
    // Depth (0 = far/small/faint, 1 = close/large/bright)
    let depth: Double
    // Lissajous wandering curve — each petal traces a unique shape
    let curveFreqA, curveFreqB: Double
    let curveRadius: Double
    let phaseA, phaseB: Double
    // Gust modulation
    let gustFreq, phaseGust: Double
    // Vertical bob (updraft / downdraft)
    let bobFreq, bobAmp: Double
    let phaseBob: Double
    // Lateral sway (for bezier wind directions)
    let swayFreqX, swayFreqY: Double
    let swayAmpX, swayAmpY: Double
    // Drift
    let driftX: Double
    // Spin & tumble
    let spinSpeed: Double
    let tumbleSpeed: CGFloat
    // Color
    let colorR, colorG, colorB: Double
    // Rotation phases
    let phaseRot: Double
    let phaseTumble: CGFloat
    let baseOpacity: Double

    init(index: Int) {
        let i = Double(index)

        func hash(_ a: Double, _ b: Double) -> Double {
            let v = sin(a + b) * 43758.5453
            return v - floor(v)
        }

        let r1 = hash(i * 127.1, 311.7)
        r2 = hash(i * 269.5, 183.3)
        r3 = hash(i * 419.2, 571.1)
        r4 = hash(i * 631.8, 223.9)
        r5 = hash(i * 157.3, 493.1)
        r6 = hash(i * 743.6, 109.4)

        // Tight stagger — most petals active by the transition moment
        stagger = r1 * 0.35

        // Continuous depth: affects size, opacity, curve radius, bob
        depth = r2
        let sizeScale = 0.6 + depth * 0.9
        baseSize = CGFloat((22 + r3 * 30) * sizeScale)

        // Lissajous frequency ratios — create unique wandering shapes per petal
        curveFreqA = 1.0 + floor(hash(i * 853.1, 427.3) * 3.0)
        curveFreqB = 1.0 + floor(hash(i * 317.9, 691.2) * 4.0)
        curveRadius = (15.0 + hash(i * 547.3, 283.7) * 30.0) * (0.6 + depth * 0.8)
        phaseA = hash(i * 193.7, 823.1) * 2.0 * .pi
        phaseB = hash(i * 461.3, 719.8) * 2.0 * .pi

        gustFreq = 1.0 + r3 * 1.5
        phaseGust = hash(i * 331.7, 557.9) * 2.0 * .pi

        bobFreq = 1.8 + r5 * 2.5
        bobAmp = (5.0 + r4 * 12.0) * (0.5 + depth * 0.5)
        phaseBob = hash(i * 773.3, 149.1) * 2.0 * .pi

        swayFreqX = 1.5 + r5 * 2.5
        swayFreqY = 1.2 + r6 * 2.0
        swayAmpX = 16.0 + r3 * 24.0
        swayAmpY = 8.0 + r4 * 14.0

        driftX = (hash(i * 911.3, 173.7) - 0.5) * 70.0

        spinSpeed = 0.6 + r6 * 1.4
        tumbleSpeed = CGFloat(1.5 + r3 * 3.0)
        phaseRot = hash(i * 617.3, 359.1) * 2.0 * .pi
        phaseTumble = CGFloat(hash(i * 241.9, 587.3) * 2.0 * .pi)

        baseOpacity = 0.4 + depth * 0.6

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

    @State private var startTime = Date()
    @State private var fadeOpacity: Double = 0

    private let duration: TimeInterval = 3.0
    private static let seeds: [PetalSeed] = (0..<200).map { PetalSeed(index: $0) }
    private static let unitPath: Path = ParticleData.petalPath(size: 1)

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
            .allowsHitTesting(true)
            .ignoresSafeArea()
        }
    }

    // MARK: - Background

    private func drawBackground(
        in context: inout GraphicsContext, size: CGSize, progress: Double
    ) {
        let peakStart = 0.22
        let peakEnd   = 0.48
        let fadeEnd   = 0.70

        let opacity: Double
        if progress < peakStart {
            let t = progress / peakStart
            opacity = t * t * 0.50
        } else if progress < peakEnd {
            opacity = 0.50
        } else if progress < fadeEnd {
            let t = (progress - peakEnd) / (fadeEnd - peakEnd)
            opacity = 0.50 * (1.0 - t * t)
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
        let windDir: Double = wind == .leftToRight ? 1.0 : -1.0

        for seed in Self.seeds {
            drawPetal(
                seed: seed, progress: progress, windDir: windDir,
                context: &context, size: size, path: path
            )
        }
    }

    private func drawPetal(
        seed: PetalSeed, progress: Double, windDir: Double,
        context: inout GraphicsContext, size: CGSize, path: Path
    ) {
        let localP = Swift.max(0, Swift.min(1, (progress - seed.stagger) / (1.0 - seed.stagger)))
        guard localP > 0 else { return }

        let w = Double(size.width)
        let h = Double(size.height)
        let petalSize = seed.baseSize

        // Wind gust — amplitude pulses between 40% and 100%
        let gust = 0.4 + 0.6 * sin(localP * seed.gustFreq * .pi + seed.phaseGust)

        var x: Double
        var y: Double

        switch wind {
        case .original:
            // ---- Gravity fall + Lissajous wandering curve ----
            let startY = -20.0 - seed.r4 * 100.0
            let endY = h + 40.0 + seed.r3 * 40.0

            let fallP = localP * (0.7 + 0.3 * localP)
            y = startY + (endY - startY) * fallP

            // Lissajous curve — each petal traces a unique shape
            let angle = localP * 2.0 * .pi
            let curveX = sin(seed.curveFreqA * angle + seed.phaseA)
                * seed.curveRadius * gust
            let curveY = sin(seed.curveFreqB * angle + seed.phaseB)
                * seed.curveRadius * 0.35 * gust

            let baseX = (seed.r3 * 1.1 - 0.05) * w
            x = baseX + curveX + seed.driftX * localP
            y += curveY

            // Vertical bob
            y += sin(localP * seed.bobFreq * .pi + seed.phaseBob) * seed.bobAmp

        case .rightToLeft:
            // ---- Bezier arc from right to left ----
            let sX = w + 40 + seed.r3 * 100
            let sY = seed.r4 * h
            let cX = (0.2 + seed.r2 * 0.6) * w
            let cY = sY + (seed.r5 - 0.3) * h * 0.25
            let eX = -60.0 - seed.r5 * 80
            let eY = sY + (seed.r6 - 0.3) * h * 0.3

            let inv = 1.0 - localP
            x = inv * inv * sX + 2 * inv * localP * cX + localP * localP * eX
            y = inv * inv * sY + 2 * inv * localP * cY + localP * localP * eY
            x += sin(localP * seed.swayFreqX * .pi + seed.phaseA) * seed.swayAmpX * 0.3 * gust
            y += cos(localP * seed.swayFreqY * .pi + seed.phaseB) * seed.swayAmpY * gust
            y += sin(localP * seed.bobFreq * .pi + seed.phaseBob) * seed.bobAmp * 0.5

        case .leftToRight:
            // ---- Mirror: bezier from left to right ----
            let sX = -40.0 - seed.r3 * 100
            let sY = seed.r4 * h
            let cX = (0.4 + seed.r2 * 0.6) * w
            let cY = sY + (seed.r5 - 0.3) * h * 0.25
            let eX = w + 60 + seed.r5 * 80
            let eY = sY + (seed.r6 - 0.3) * h * 0.3

            let inv = 1.0 - localP
            x = inv * inv * sX + 2 * inv * localP * cX + localP * localP * eX
            y = inv * inv * sY + 2 * inv * localP * cY + localP * localP * eY
            x += sin(localP * seed.swayFreqX * .pi + seed.phaseA) * seed.swayAmpX * 0.3 * gust
            y += cos(localP * seed.swayFreqY * .pi + seed.phaseB) * seed.swayAmpY * gust
            y += sin(localP * seed.bobFreq * .pi + seed.phaseBob) * seed.bobAmp * 0.5
        }

        // ---- Opacity: journey fade + edge softening ----
        let fadeIn = Swift.min(1.0, localP / 0.10)
        let fadeOut = Swift.min(1.0, (1.0 - localP) / 0.30)
        let journeyFade = fadeIn * fadeOut

        let ep = 100.0
        var edgeFade = 1.0
        edgeFade = Swift.min(edgeFade, Swift.max(0, y + ep) / ep)
        edgeFade = Swift.min(edgeFade, Swift.max(0, h + ep - y) / ep)
        edgeFade = Swift.min(edgeFade, Swift.max(0, x + ep) / ep)
        edgeFade = Swift.min(edgeFade, Swift.max(0, w + ep - x) / ep)

        let fade = journeyFade * edgeFade * seed.baseOpacity
        guard fade > 0.01 else { return }

        // Rotation & tumble
        let spinDir: Double = wind == .original ? 1.0 : windDir
        let rotation = CGFloat(seed.phaseRot + localP * .pi * seed.spinSpeed * spinDir)
        let tumble = cos(CGFloat(localP) * seed.tumbleSpeed + seed.phaseTumble)
        let faceAmount = abs(tumble)

        // --- Draw ---
        var ctx = context
        ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
        ctx.rotate(by: .radians(rotation))
        ctx.scaleBy(x: petalSize, y: petalSize)
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
