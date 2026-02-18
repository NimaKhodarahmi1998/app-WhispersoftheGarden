//
//  GardenHintView.swift
//  WhispersoftheGardenApp
//
//  Atmospheric hint that feels like the garden whispering.
//  Spotlight vignette, radial glow beacon, rising motes,
//  cascading glow ripples, and a text pill guide the user
//  without breaking the mood.
//

import SwiftUI

enum GardenHintMode {
    case tutorial   // spotlight + glow + motes + ripples + text
    case invitation // spotlight + glow + ripples only, subtler opacity
}

struct GardenHintView: View {
    let stage: GardenHintStage
    let targetPosition: CGPoint
    let screenSize: CGSize
    let reduceMotion: Bool
    let mode: GardenHintMode

    @State private var ring0: CGFloat = 0
    @State private var ring1: CGFloat = 0
    @State private var ring2: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 4
    @State private var breathe: CGFloat = 0

    private var color: Color {
        switch stage {
        case .tapPool:        return .persianTurquoise
        case .tapLilyPad:     return .persianSaffron
        case .tapNightingale: return .persianGold
        }
    }

    private var hintText: String {
        switch stage {
        case .tapPool:        return "Touch the water\u{2026}"
        case .tapLilyPad:     return "Gently, on the leaf\u{2026}"
        case .tapNightingale: return "The nightingale awaits\u{2026}"
        }
    }

    private var opacityScale: Double {
        mode == .tutorial ? 1.0 : 0.6
    }

    private let baseRadius: CGFloat = 28

    var body: some View {
        ZStack {
            Color.clear

            if reduceMotion {
                staticHint
            } else {
                animatedHint
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Reduce Motion

    private var staticHint: some View {
        let c = color
        let r = baseRadius
        let pos = targetPosition
        let os = opacityScale
        return ZStack {
            // Static spotlight vignette
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.30 * os)],
                center: UnitPoint(
                    x: pos.x / screenSize.width,
                    y: pos.y / screenSize.height
                ),
                startRadius: 120,
                endRadius: 320
            )
            .ignoresSafeArea()

            // Static glow beacon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [c.opacity(0.35 * os), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .position(pos)

            // Static ripple ring
            Circle()
                .stroke(c.opacity(0.5 * os), lineWidth: 3)
                .blur(radius: 4)
                .frame(width: r * 2, height: r * 2)
                .position(pos)

            if mode == .tutorial {
                HintLabel(text: hintText, color: c, position: pos, baseRadius: r,
                          opacity: 0.85, yOffset: 0)
            }
        }
    }

    // MARK: - Animated

    private var animatedHint: some View {
        let c = color
        let r = baseRadius
        let pos = targetPosition
        let os = opacityScale
        // breathe interpolates 0→1 for pulsing effects
        let spotlightOpacity = (0.25 + breathe * 0.15) * os
        let glowOpacity = (0.25 + breathe * 0.20) * os

        return ZStack {
            // 1. Spotlight vignette
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.35)],
                center: UnitPoint(
                    x: pos.x / screenSize.width,
                    y: pos.y / screenSize.height
                ),
                startRadius: 120,
                endRadius: 320
            )
            .ignoresSafeArea()
            .opacity(spotlightOpacity / 0.35) // normalize so edge = spotlightOpacity

            // 2. Radial glow beacon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [c.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .position(pos)

            // 3. Rising motes
            HintMotesCanvas(color: c, targetPosition: pos)
                .opacity(os)

            // 4. Glow ripple rings
            HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring0)
                .opacity(os)
            HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring1)
                .opacity(os)
            HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring2)
                .opacity(os)

            // 5. Text label with pill (tutorial only)
            if mode == .tutorial {
                HintLabel(text: hintText, color: c, position: pos, baseRadius: r,
                          opacity: textOpacity, yOffset: textOffset)
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Animation triggers

    private func startAnimations() {
        withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
            ring0 = 1
        }
        withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(0.8)) {
            ring1 = 1
        }
        withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(1.6)) {
            ring2 = 1
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.4)) {
            textOpacity = 0.9
            textOffset = -2
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathe = 1
        }
    }
}

// MARK: - Ripple Ring

private struct HintRippleRing: View {
    let color: Color
    let baseRadius: CGFloat
    let position: CGPoint
    let progress: CGFloat

    var body: some View {
        let scale = 1.0 + progress * 1.4
        let op = Double((1.0 - progress) * 0.7)

        Circle()
            .stroke(color.opacity(op), lineWidth: 3)
            .blur(radius: 4)
            .frame(width: baseRadius * 2, height: baseRadius * 2)
            .scaleEffect(scale)
            .position(position)
    }
}

// MARK: - Rising Motes (Canvas)

private struct HintMote {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    var swayPhase: CGFloat
    var swayAmount: CGFloat
}

private final class HintMoteData: ObservableObject, @unchecked Sendable {
    var motes: [HintMote] = []
    var lastTime: TimeInterval = 0
    var initialized = false

    func setup(center: CGPoint) {
        guard !initialized else { return }
        initialized = true
        for _ in 0..<6 {
            motes.append(Self.makeMote(center: center, randomY: true))
        }
    }

    func update(time: TimeInterval, center: CGPoint) {
        let dt = lastTime == 0 ? 0.016 : min(time - lastTime, 0.05)
        lastTime = time

        if !initialized { setup(center: center) }

        for i in motes.indices {
            motes[i].y -= motes[i].speed * CGFloat(dt)
            let sway = CGFloat(sin(time * 1.2 + Double(motes[i].swayPhase))) * motes[i].swayAmount
            motes[i].x = center.x + sway

            // Fade as they rise
            let travel = center.y - motes[i].y
            let maxTravel: CGFloat = 80
            if travel > maxTravel * 0.5 {
                motes[i].opacity = max(0, motes[i].opacity - CGFloat(dt) * 0.6)
            }

            // Respawn when faded or too high
            if motes[i].y < center.y - maxTravel || motes[i].opacity <= 0 {
                motes[i] = Self.makeMote(center: center, randomY: false)
            }
        }
    }

    func render(in context: inout GraphicsContext, moteColor: Color) {
        for mote in motes {
            var ctx = context
            ctx.translateBy(x: mote.x, y: mote.y)

            let r = mote.size
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)

            ctx.fill(
                Circle().path(in: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        moteColor.opacity(Double(mote.opacity)),
                        moteColor.opacity(Double(mote.opacity) * 0.3),
                        .clear
                    ]),
                    center: .zero,
                    startRadius: 0,
                    endRadius: r
                )
            )
        }
    }

    static func makeMote(center: CGPoint, randomY: Bool) -> HintMote {
        HintMote(
            x: center.x + .random(in: -20...20),
            y: randomY ? center.y - .random(in: 0...60) : center.y + .random(in: -5...5),
            size: .random(in: 1.5...3.0),
            opacity: .random(in: 0.3...0.6),
            speed: .random(in: 14...26),
            swayPhase: .random(in: 0...(2 * .pi)),
            swayAmount: .random(in: 8...20)
        )
    }
}

private struct HintMotesCanvas: View {
    let color: Color
    let targetPosition: CGPoint

    @StateObject private var system = HintMoteData()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                system.update(
                    time: timeline.date.timeIntervalSinceReferenceDate,
                    center: targetPosition
                )
                system.render(in: &context, moteColor: color)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Label with Pill Background

private struct HintLabel: View {
    let text: String
    let color: Color
    let position: CGPoint
    let baseRadius: CGFloat
    let opacity: Double
    let yOffset: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .medium, design: .serif))
            .italic()
            .foregroundStyle(gradient)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
            )
            .shadow(color: color.opacity(0.3), radius: 12)
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            .opacity(opacity)
            .offset(y: yOffset)
            .position(x: position.x, y: position.y + baseRadius * 2.4)
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.white, color.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
