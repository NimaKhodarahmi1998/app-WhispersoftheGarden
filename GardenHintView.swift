//
//  GardenHintView.swift
//  WhispersoftheGardenApp
//
//  Atmospheric hint that feels like the garden whispering.
//  Pool/lily pad: spotlight vignette, radial glow, rising motes, ripple rings.
//  Nightingale: warm golden aura, falling golden dust, rotating shimmer rays.
//  Tutorial mode adds a text pill; invitation mode is effects only.
//

import SwiftUI

enum GardenHintMode {
    case tutorial   // spotlight + glow + effects + text
    case invitation // glow + effects only, no text
}

struct GardenHintView: View {
    let stage: GardenHintStage
    let targetPosition: CGPoint
    let screenSize: CGSize
    let reduceMotion: Bool
    let mode: GardenHintMode
    var effectsOpacity: Double = 1.0  // fades bright effects without touching the vignette

    @State private var ring0: CGFloat = 0
    @State private var ring1: CGFloat = 0
    @State private var ring2: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 4
    @State private var breathe: CGFloat = 0
    @State private var shimmerAngle: Double = 0

    private var color: Color {
        switch stage {
        case .tapPool:           return .persianTurquoise
        case .tapLilyPad:        return .persianSaffron
        case .dragPool:          return .persianTurquoise
        case .tapPoolAgain:      return .persianTurquoise
        case .tapSecondLilyPad:  return .persianSaffron
        case .tapPoolThrice:     return .persianTurquoise
        case .tapThirdLilyPad:   return .persianSaffron
        case .longPressPool:     return .persianTurquoise
        case .tapNightingale:    return .persianGold
        }
    }

    private var hintText: String {
        switch stage {
        case .tapPool:           return "Touch the water\u{2026} a leaf will appear"
        case .tapLilyPad:        return "Tap the leaf\u{2026} it holds a hidden verse"
        case .dragPool:          return "Trace the water to play Santur\u{2026}"
        case .tapPoolAgain:      return "Touch the water again\u{2026} another leaf awaits"
        case .tapSecondLilyPad:  return "Tap to bloom\u{2026} each lotus reveals a poem"
        case .tapPoolThrice:     return "Once more\u{2026} the garden has more to give"
        case .tapThirdLilyPad:   return "Bloom the leaf\u{2026} a poet\u{2019}s voice is inside"
        case .longPressPool:     return "Linger on the water\u{2026} patience reveals more"
        case .tapNightingale:    return "The nightingale carries a verse\u{2026} tap gently"
        }
    }

    private var opacityScale: Double {
        mode == .tutorial ? 1.0 : 0.85
    }

    private var isNightingale: Bool { stage == .tapNightingale }

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
            // Vignette — stays independent of effectsOpacity
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.40 * os)],
                center: UnitPoint(
                    x: pos.x / screenSize.width,
                    y: pos.y / screenSize.height
                ),
                startRadius: 120,
                endRadius: 320
            )
            .ignoresSafeArea()

            // Bright effects — scaled by effectsOpacity
            Group {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [c.opacity(0.50 * os), c.opacity(0.15 * os), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: isNightingale ? 150 : 130
                        )
                    )
                    .frame(width: isNightingale ? 300 : 260,
                           height: isNightingale ? 300 : 260)
                    .position(pos)

                Circle()
                    .fill(c)
                    .frame(width: 12, height: 12)
                    .opacity(0.7 * os)
                    .blur(radius: 3)
                    .position(pos)

                if isNightingale {
                    HolySpotlight(
                        color: c, targetPosition: pos, screenSize: screenSize,
                        opacityScale: os
                    )
                    .opacity(0.55)
                } else {
                    Circle()
                        .stroke(c.opacity(0.7 * os), lineWidth: 4)
                        .blur(radius: 3)
                        .frame(width: r * 2, height: r * 2)
                        .position(pos)
                }

                if mode == .tutorial {
                    HintLabel(text: hintText, color: c, position: pos, baseRadius: r,
                              opacity: 0.85, yOffset: 0)
                }
            }
            .opacity(effectsOpacity)
        }
    }

    // MARK: - Animated

    private var animatedHint: some View {
        let c = color
        let r = baseRadius
        let pos = targetPosition
        let os = opacityScale
        let spotlightOpacity = (0.35 + breathe * 0.20) * os
        let glowOpacity = (0.40 + breathe * 0.25) * os

        return ZStack {
            // 1. Spotlight vignette — deeper for nightingale
            RadialGradient(
                colors: [.clear, Color.black.opacity(isNightingale ? 0.55 : 0.35)],
                center: UnitPoint(
                    x: pos.x / screenSize.width,
                    y: pos.y / screenSize.height
                ),
                startRadius: isNightingale ? 80 : 120,
                endRadius: isNightingale ? 280 : 320
            )
            .ignoresSafeArea()
            .opacity(spotlightOpacity / 0.35)

            // All bright effects — scaled by effectsOpacity (vignette above stays independent)
            Group {
                // 2. Radial glow beacon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isNightingale
                                ? [Color.white.opacity(glowOpacity * 0.5),
                                   c.opacity(glowOpacity),
                                   c.opacity(glowOpacity * 0.3),
                                   .clear]
                                : [c.opacity(glowOpacity),
                                   c.opacity(glowOpacity * 0.3),
                                   .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: isNightingale ? 200 : 130
                        )
                    )
                    .frame(width: isNightingale ? 400 : 260,
                           height: isNightingale ? 400 : 260)
                    .position(pos)

                if isNightingale {
                    // --- Nightingale: THE HOLIEST BEING ON EARTH ---

                    // Holy spotlight — blur cached via drawingGroup,
                    // breathe only drives external .opacity() (no blur recompute)
                    HolySpotlight(
                        color: c, targetPosition: pos, screenSize: screenSize,
                        opacityScale: os
                    )
                    .opacity(0.45 + Double(breathe) * 0.20)

                    // Divine halo behind the nightingale
                    NightingaleHalo(color: c, position: pos,
                                    breathe: breathe, opacityScale: os)

                    // Rotating shimmer rays — brighter, more rays
                    NightingaleRaysView(
                        color: c, position: pos, angle: shimmerAngle,
                        breathe: breathe, opacityScale: os
                    )

                    // Ascending holy sparks
                    HolySparkCanvas(color: c, targetPosition: pos, isActive: effectsOpacity > 0.05)
                        .opacity(os)

                    // Falling golden dust
                    NightingaleDustCanvas(color: c, targetPosition: pos, isActive: effectsOpacity > 0.05)
                        .opacity(os)

                    // Radiant pulsing star at center
                    NightingaleStar(color: c, position: pos,
                                    breathe: breathe, opacityScale: os)

                } else {
                    // --- Pool / Lily Pad: ripple rings + rising motes ---

                    // Bright pulsing center dot
                    Circle()
                        .fill(c)
                        .frame(width: 10 + breathe * 4, height: 10 + breathe * 4)
                        .opacity((0.6 + breathe * 0.3) * os)
                        .blur(radius: 3)
                        .position(pos)

                    // Rising motes
                    HintMotesCanvas(color: c, targetPosition: pos)
                        .opacity(os)

                    // Glow ripple rings
                    HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring0)
                        .opacity(os)
                    HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring1)
                        .opacity(os)
                    HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring2)
                        .opacity(os)
                }

                // Text label (tutorial only)
                if mode == .tutorial {
                    HintLabel(text: hintText, color: c, position: pos, baseRadius: r,
                              opacity: textOpacity, yOffset: textOffset)
                }
            }
            .opacity(effectsOpacity)
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
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            shimmerAngle = .pi * 2
        }
    }
}

// MARK: - Pool/Lily Pad: Ripple Ring

private struct HintRippleRing: View {
    let color: Color
    let baseRadius: CGFloat
    let position: CGPoint
    let progress: CGFloat

    var body: some View {
        let scale = 1.0 + progress * 2.0
        let op = Double((1.0 - progress) * 0.9)

        Circle()
            .stroke(color.opacity(op), lineWidth: 4)
            .blur(radius: 3)
            .frame(width: baseRadius * 2, height: baseRadius * 2)
            .scaleEffect(scale)
            .position(position)
    }
}

// MARK: - Pool/Lily Pad: Rising Motes (Canvas)

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
        for _ in 0..<10 {
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

            let travel = center.y - motes[i].y
            let maxTravel: CGFloat = 80
            if travel > maxTravel * 0.5 {
                motes[i].opacity = max(0, motes[i].opacity - CGFloat(dt) * 0.6)
            }

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
            x: center.x + .random(in: -28...28),
            y: randomY ? center.y - .random(in: 0...70) : center.y + .random(in: -5...5),
            size: .random(in: 2.5...5.0),
            opacity: .random(in: 0.5...0.85),
            speed: .random(in: 16...30),
            swayPhase: .random(in: 0...(2 * .pi)),
            swayAmount: .random(in: 10...24)
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

// MARK: - Nightingale: Rotating Shimmer Rays

private struct NightingaleRaysView: View {
    let color: Color
    let position: CGPoint
    let angle: Double
    let breathe: CGFloat
    let opacityScale: Double

    private let rayCount = 8
    private let rayLength: CGFloat = 130

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let center = position
            let baseOp = (0.30 + Double(breathe) * 0.20) * opacityScale

            for i in 0..<rayCount {
                let rayAngle = angle + Double(i) * (.pi * 2.0 / Double(rayCount))
                let dx = cos(rayAngle)
                let dy = sin(rayAngle)

                // Wider rays compensate for removed blur — gradient edges stay soft
                let thisLength = (i % 2 == 0) ? rayLength : rayLength * 0.7
                let thisWidth: CGFloat = (i % 2 == 0) ? 20 : 14

                let tipX = center.x + CGFloat(dx) * thisLength
                let tipY = center.y + CGFloat(dy) * thisLength
                let perpX = CGFloat(-dy) * thisWidth
                let perpY = CGFloat(dx) * thisWidth

                var path = Path()
                path.move(to: CGPoint(x: center.x + perpX, y: center.y + perpY))
                path.addLine(to: CGPoint(x: tipX, y: tipY))
                path.addLine(to: CGPoint(x: center.x - perpX, y: center.y - perpY))
                path.closeSubpath()

                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            .white.opacity(baseOp * 0.6),
                            color.opacity(baseOp),
                            color.opacity(baseOp * 0.3),
                            .clear
                        ]),
                        startPoint: center,
                        endPoint: CGPoint(x: tipX, y: tipY)
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Nightingale: Pulsing Star at Center

private struct NightingaleStar: View {
    let color: Color
    let position: CGPoint
    let breathe: CGFloat
    let opacityScale: Double

    var body: some View {
        let starOp = (0.80 + breathe * 0.20) * opacityScale
        let starSize: CGFloat = 18 + breathe * 10

        ZStack {
            // Wide radiant glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.5),
                            color.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: starSize * 2.5
                    )
                )
                .frame(width: starSize * 5, height: starSize * 5)

            // Horizontal streak
            Capsule()
                .fill(color)
                .frame(width: starSize * 3.0, height: starSize * 0.4)
                .blur(radius: 3)

            // Vertical streak
            Capsule()
                .fill(color)
                .frame(width: starSize * 0.4, height: starSize * 3.0)
                .blur(radius: 3)

            // Diagonal streaks for 8-pointed star
            Capsule()
                .fill(color.opacity(0.6))
                .frame(width: starSize * 2.2, height: starSize * 0.3)
                .rotationEffect(.degrees(45))
                .blur(radius: 2)

            Capsule()
                .fill(color.opacity(0.6))
                .frame(width: starSize * 2.2, height: starSize * 0.3)
                .rotationEffect(.degrees(-45))
                .blur(radius: 2)

            // White-hot core
            Circle()
                .fill(.white)
                .frame(width: starSize * 0.7, height: starSize * 0.7)
                .blur(radius: 4)
        }
        .opacity(starOp)
        .position(position)
    }
}

// MARK: - Nightingale: Holy Spotlight from Above

private struct HolySpotlight: View {
    let color: Color
    let targetPosition: CGPoint
    let screenSize: CGSize
    let opacityScale: Double
    // breathe removed — caller applies it via .opacity() so blurs are never recomputed.

    var body: some View {
        let pos = targetPosition
        let baseOp = opacityScale
        let warmWhite = Color(red: 1.0, green: 0.97, blue: 0.88)

        // Inner beam — concentrated
        let topLeft  = CGPoint(x: pos.x - 80, y: -20)
        let topRight = CGPoint(x: pos.x + 80, y: -20)
        let botLeft  = CGPoint(x: pos.x - 32, y: pos.y - 8)
        let botRight = CGPoint(x: pos.x + 32, y: pos.y - 8)

        // Mid beam
        let midTopLeft  = CGPoint(x: pos.x - 140, y: -20)
        let midTopRight = CGPoint(x: pos.x + 140, y: -20)
        let midBotLeft  = CGPoint(x: pos.x - 55, y: pos.y + 14)
        let midBotRight = CGPoint(x: pos.x + 55, y: pos.y + 14)

        // Wide outer wash
        let outerTopLeft  = CGPoint(x: pos.x - 200, y: -20)
        let outerTopRight = CGPoint(x: pos.x + 200, y: -20)
        let outerBotLeft  = CGPoint(x: pos.x - 80, y: pos.y + 30)
        let outerBotRight = CGPoint(x: pos.x + 80, y: pos.y + 30)

        ZStack {
            // drawingGroup flattens the 3 blurred paths into a single cached
            // Metal texture. Since inputs are constant (no breathe), the texture
            // is computed once. The caller's .opacity() just alpha-blends it.
            Group {
                // Wide outer wash — ethereal golden flood
                Path { path in
                    path.move(to: outerTopLeft)
                    path.addLine(to: outerTopRight)
                    path.addLine(to: outerBotRight)
                    path.addLine(to: outerBotLeft)
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(baseOp * 0.4),
                            color.opacity(baseOp * 0.25),
                            color.opacity(baseOp * 0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 36)

                // Mid beam — warm golden cone
                Path { path in
                    path.move(to: midTopLeft)
                    path.addLine(to: midTopRight)
                    path.addLine(to: midBotRight)
                    path.addLine(to: midBotLeft)
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            warmWhite.opacity(baseOp * 0.5),
                            color.opacity(baseOp * 0.55),
                            color.opacity(baseOp * 0.20),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 20)

                // Inner bright beam — white-hot core
                Path { path in
                    path.move(to: topLeft)
                    path.addLine(to: topRight)
                    path.addLine(to: botRight)
                    path.addLine(to: botLeft)
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(baseOp * 0.75),
                            warmWhite.opacity(baseOp * 0.65),
                            color.opacity(baseOp * 0.35),
                            color.opacity(baseOp * 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 10)
            }
            .drawingGroup(opaque: false)

            // Blazing source glow at top — where the heavens open
            RadialGradient(
                colors: [
                    Color.white.opacity(baseOp * 0.7),
                    warmWhite.opacity(baseOp * 0.5),
                    color.opacity(baseOp * 0.25),
                    Color.clear
                ],
                center: UnitPoint(x: pos.x / screenSize.width, y: 0),
                startRadius: 0,
                endRadius: 140
            )
            .ignoresSafeArea()

            // Radiant pool of light at the nightingale's feet
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(baseOp * 0.5),
                            warmWhite.opacity(baseOp * 0.35),
                            color.opacity(baseOp * 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 40)
                .position(x: pos.x, y: pos.y + 16)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Nightingale: Falling Golden Dust (Canvas)

private struct NightingaleDustParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    var swayPhase: CGFloat
    var swayAmount: CGFloat
    var elongation: CGFloat  // 1.0 = circle, >1 = taller (feather-like)
}

private final class NightingaleDustData: ObservableObject, @unchecked Sendable {
    var particles: [NightingaleDustParticle] = []
    var lastTime: TimeInterval = 0
    var initialized = false

    func setup(center: CGPoint) {
        guard !initialized else { return }
        initialized = true
        for _ in 0..<20 {
            particles.append(Self.makeParticle(center: center, randomY: true))
        }
    }

    func update(time: TimeInterval, center: CGPoint) {
        let dt = lastTime == 0 ? 0.016 : min(time - lastTime, 0.05)
        lastTime = time

        if !initialized { setup(center: center) }

        for i in particles.indices {
            // Fall downward
            particles[i].y += particles[i].speed * CGFloat(dt)

            // Gentle S-curve sway
            let sway = CGFloat(sin(time * 0.8 + Double(particles[i].swayPhase)))
                * particles[i].swayAmount
            particles[i].x = center.x + sway

            // Fade as they fall away from center
            let travel = particles[i].y - center.y
            let maxTravel: CGFloat = 100
            if travel > maxTravel * 0.4 {
                particles[i].opacity = max(0, particles[i].opacity - CGFloat(dt) * 0.5)
            }

            // Respawn when faded or too low
            if particles[i].y > center.y + maxTravel || particles[i].opacity <= 0 {
                particles[i] = Self.makeParticle(center: center, randomY: false)
            }
        }
    }

    func render(in context: inout GraphicsContext, dustColor: Color) {
        for p in particles {
            var ctx = context
            ctx.translateBy(x: p.x, y: p.y)

            let w = p.size
            let h = p.size * p.elongation
            let rect = CGRect(x: -w, y: -h, width: w * 2, height: h * 2)

            ctx.fill(
                Ellipse().path(in: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        dustColor.opacity(Double(p.opacity)),
                        dustColor.opacity(Double(p.opacity) * 0.2),
                        .clear
                    ]),
                    center: .zero,
                    startRadius: 0,
                    endRadius: max(w, h)
                )
            )
        }
    }

    static func makeParticle(center: CGPoint, randomY: Bool) -> NightingaleDustParticle {
        NightingaleDustParticle(
            x: center.x + .random(in: -50...50),
            y: randomY ? center.y + .random(in: -60...60) : center.y - .random(in: 15...40),
            size: .random(in: 2.5...5.5),
            opacity: .random(in: 0.55...0.90),
            speed: .random(in: 10...22),
            swayPhase: .random(in: 0...(2 * .pi)),
            swayAmount: .random(in: 18...40),
            elongation: .random(in: 1.3...2.2)
        )
    }
}

private struct NightingaleDustCanvas: View {
    let color: Color
    let targetPosition: CGPoint
    var isActive: Bool = true

    @StateObject private var system = NightingaleDustData()

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                guard isActive else { return }
                system.update(
                    time: timeline.date.timeIntervalSinceReferenceDate,
                    center: targetPosition
                )
                system.render(in: &context, dustColor: color)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Nightingale: Divine Halo

private struct NightingaleHalo: View {
    let color: Color
    let position: CGPoint
    let breathe: CGFloat
    let opacityScale: Double

    var body: some View {
        let haloOp = (0.50 + Double(breathe) * 0.25) * opacityScale
        let haloSize: CGFloat = 60 + breathe * 14

        ZStack {
            // Outer soft halo ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            color.opacity(haloOp * 0.7),
                            Color.white.opacity(haloOp * 0.5),
                            color.opacity(haloOp * 0.7),
                            Color.white.opacity(haloOp * 0.5),
                            color.opacity(haloOp * 0.7)
                        ],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: haloSize * 2.2, height: haloSize * 1.4)
                .blur(radius: 5)

            // Inner bright ring
            Circle()
                .stroke(Color.white.opacity(haloOp * 0.45), lineWidth: 2)
                .frame(width: haloSize * 1.8, height: haloSize * 1.1)
                .blur(radius: 3)

            // Fill glow inside halo
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(haloOp * 0.15),
                            color.opacity(haloOp * 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: haloSize * 0.9
                    )
                )
                .frame(width: haloSize * 2.0, height: haloSize * 1.2)
        }
        .position(x: position.x, y: position.y - 18)
    }
}

// MARK: - Nightingale: Ascending Holy Sparks

private struct HolySpark {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    var swayPhase: CGFloat
    var swayAmount: CGFloat
    var brightness: CGFloat  // 0 = gold, 1 = white
}

private final class HolySparkData: ObservableObject, @unchecked Sendable {
    var sparks: [HolySpark] = []
    var lastTime: TimeInterval = 0
    var initialized = false

    func setup(center: CGPoint) {
        guard !initialized else { return }
        initialized = true
        for _ in 0..<16 {
            sparks.append(Self.makeSpark(center: center, randomY: true))
        }
    }

    func update(time: TimeInterval, center: CGPoint) {
        let dt = lastTime == 0 ? 0.016 : min(time - lastTime, 0.05)
        lastTime = time

        if !initialized { setup(center: center) }

        for i in sparks.indices {
            // Rise upward
            sparks[i].y -= sparks[i].speed * CGFloat(dt)

            // Gentle sway
            let sway = CGFloat(sin(time * 1.5 + Double(sparks[i].swayPhase)))
                * sparks[i].swayAmount
            sparks[i].x = center.x + sway

            // Twinkle — pulsing brightness
            let twinkle = CGFloat(sin(time * 4.0 + Double(sparks[i].swayPhase * 2))) * 0.3 + 0.7
            sparks[i].opacity = min(sparks[i].opacity, twinkle)

            // Fade as they rise
            let travel = center.y - sparks[i].y
            let maxTravel: CGFloat = 120
            if travel > maxTravel * 0.4 {
                sparks[i].opacity = max(0, sparks[i].opacity - CGFloat(dt) * 0.5)
            }

            if sparks[i].y < center.y - maxTravel || sparks[i].opacity <= 0 {
                sparks[i] = Self.makeSpark(center: center, randomY: false)
            }
        }
    }

    func render(in context: inout GraphicsContext, goldColor: Color) {
        for spark in sparks {
            var ctx = context
            ctx.translateBy(x: spark.x, y: spark.y)

            let r = spark.size
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)

            // Blend gold and white based on brightness
            let sparkColor = spark.brightness > 0.5 ? Color.white : goldColor

            ctx.fill(
                Circle().path(in: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        sparkColor.opacity(Double(spark.opacity)),
                        goldColor.opacity(Double(spark.opacity) * 0.4),
                        .clear
                    ]),
                    center: .zero,
                    startRadius: 0,
                    endRadius: r
                )
            )
        }
    }

    static func makeSpark(center: CGPoint, randomY: Bool) -> HolySpark {
        HolySpark(
            x: center.x + .random(in: -45...45),
            y: randomY ? center.y - .random(in: -20...100) : center.y + .random(in: -5...10),
            size: .random(in: 1.5...4.0),
            opacity: .random(in: 0.6...1.0),
            speed: .random(in: 18...38),
            swayPhase: .random(in: 0...(2 * .pi)),
            swayAmount: .random(in: 12...30),
            brightness: .random(in: 0...1)
        )
    }
}

private struct HolySparkCanvas: View {
    let color: Color
    let targetPosition: CGPoint
    var isActive: Bool = true

    @StateObject private var system = HolySparkData()

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                guard isActive else { return }
                system.update(
                    time: timeline.date.timeIntervalSinceReferenceDate,
                    center: targetPosition
                )
                system.render(in: &context, goldColor: color)
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

    @ScaledMetric(relativeTo: .body) private var hintTextSize: CGFloat = 19

    var body: some View {
        Text(text)
            .font(.system(size: hintTextSize, weight: .semibold, design: .serif))
            .italic()
            .foregroundStyle(gradient)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.65))
                    .overlay(
                        Capsule()
                            .strokeBorder(color.opacity(0.35), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.5), radius: 16)
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            .opacity(opacity)
            .offset(y: yOffset)
            .position(x: position.x, y: position.y + baseRadius * 2.8)
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.white, color.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
