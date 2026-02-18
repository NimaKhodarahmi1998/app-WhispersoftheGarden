//
//  GardenHintView.swift
//  WhispersoftheGardenApp
//
//  Atmospheric hint that feels like the garden whispering.
//  Cascading ripples, a warm inner glow, and drifting motes
//  guide the user without breaking the mood.
//

import SwiftUI

struct GardenHintView: View {
    let stage: GardenHintStage
    let targetPosition: CGPoint
    let reduceMotion: Bool

    @State private var ring0: CGFloat = 0
    @State private var ring1: CGFloat = 0
    @State private var ring2: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 4

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

    private let baseRadius: CGFloat = 28

    var body: some View {
        ZStack {
            Color.clear // fill parent so .position() coordinates map correctly

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
        return ZStack {
            Circle()
                .stroke(c.opacity(0.5), lineWidth: 1.2)
                .frame(width: r * 2, height: r * 2)
                .position(pos)

            HintLabel(text: hintText, color: c, position: pos, baseRadius: r,
                      opacity: 0.85, yOffset: 0)
        }
    }

    // MARK: - Animated

    private var animatedHint: some View {
        let c = color
        let r = baseRadius
        let pos = targetPosition
        return ZStack {
            HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring0)
            HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring1)
            HintRippleRing(color: c, baseRadius: r, position: pos, progress: ring2)

            HintLabel(text: hintText, color: c, position: pos, baseRadius: r,
                      opacity: textOpacity, yOffset: textOffset)
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
    }
}

// MARK: - Ripple Ring (extracted)

private struct HintRippleRing: View {
    let color: Color
    let baseRadius: CGFloat
    let position: CGPoint
    let progress: CGFloat

    var body: some View {
        let scale = 1.0 + progress * 1.4
        let op = Double((1.0 - progress) * 0.55)
        let lw = 1.5 * (1.0 - progress * 0.6)

        Circle()
            .stroke(color.opacity(op), lineWidth: lw)
            .frame(width: baseRadius * 2, height: baseRadius * 2)
            .scaleEffect(scale)
            .position(position)
    }
}

// MARK: - Label (extracted)

private struct HintLabel: View {
    let text: String
    let color: Color
    let position: CGPoint
    let baseRadius: CGFloat
    let opacity: Double
    let yOffset: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .light, design: .serif))
            .italic()
            .foregroundStyle(gradient)
            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 0)
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

