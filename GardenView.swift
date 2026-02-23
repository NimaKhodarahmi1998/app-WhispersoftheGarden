//
//  GardenView.swift - COMPLETE WITH BACK BUTTON
//  WhispersoftheGardenApp
//
//  Lily pads in pool + Lotus bloom reveals poem + Back button
//

import SwiftUI

struct Pad: Identifiable {
    let id = UUID()
    var anchor: CGPoint
    var isLotus: Bool
    var targetAnchor: CGPoint
    var movementStyle: MovementStyle
    var phase: CGFloat
    var speed: CGFloat
    var bobOffset: CGFloat = 0
    var bobVelocity: CGFloat = 0
    var glowIntensity: CGFloat = 0
    var storedPoem: Poem?
}

struct Firefly: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var baseOpacity: Double
    var twinklePhase: CGFloat
    var speed: CGFloat
    var drift: CGFloat
}

enum MovementStyle: String, CaseIterable, Codable {
    case gentle, wavy, circular, zigzag, stillness
}

// MARK: - Garden Persistence

private struct SavedPad: Codable {
    let anchorX: CGFloat
    let anchorY: CGFloat
    let isLotus: Bool
    let movementStyle: MovementStyle
    let phase: CGFloat
    let speed: CGFloat
    let storedPoemID: String?  // UUID string for lookup
}

struct GardenView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @Binding var showMainApp: Bool
    var isActive: Bool = true  // pause updates when off-screen (e.g. Library tab)
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    private let audio = GardenAudioEngine.shared

    @ScaledMetric(relativeTo: .callout) private var whisperSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var approachWhisperSize: CGFloat = 18

    @State private var showPoem = false
    @State private var currentPoem: Poem?
    @State private var pads: [Pad] = []
    @State private var time: TimeInterval = 0
    @State private var fireflies: [Firefly] = []
    @State private var petalBurst = 0
    private let waterBridge = WaterRendererBridge()
    @State private var breathingIntensity: CGFloat = 0

    // Nightingale state
    @State private var showNightingale = false
    @State private var nightingalePosition: CGPoint = CGPoint(x: 0.12, y: 0.82)
    @State private var nightingalePerchIndex = 0
    @State private var nightingaleIsPerched = true
    @State private var nightingaleFacingRight = true
    @State private var nightingaleCoupletIndex = 0
    @State private var showNightingaleCouplet = false
    @State private var currentNightingaleCouplet: Poem?
    @State private var nightingaleAppearOpacity: Double = 0
    @State private var poolPoemsSinceNightingale: Int = 0
    @State private var nightingaleWhisperOpacity: Double = 0
    @State private var currentDepartureWhisper: String = ""
    @State private var showApproachFeather = false
    @State private var featherFallProgress: CGFloat = 0
    @State private var featherOpacity: Double = 0
    @State private var showApproachWhisper = false
    @State private var currentApproachWhisper: String = ""
    @State private var nightingaleGlowOpacity: Double = 0  // holy light fade-in

    // Bounding flight animation (timer-driven, NOT SwiftUI animation)
    @State private var nightingaleFlightT: CGFloat = 0
    @State private var nightingaleInFlight = false
    @State private var nightingaleFlightOrigin: CGPoint = .zero
    @State private var nightingaleFlightDest: CGPoint = .zero
    @State private var nightingaleIsFlyingOut = false
    @State private var nightingaleFlightStartTime: Date?
    @State private var nightingaleFlightDuration: TimeInterval = 2.2

    private let departureWhispers = [
        "The nightingale shall return\u{2026}",
        "Its song lingers in the wind\u{2026}",
        "Patience\u{2026} the melody returns\u{2026}",
        "A promise carried on the breeze\u{2026}",
        "The song fades, but not forever\u{2026}",
        "Until the garden calls again\u{2026}",
    ]

    private let approachWhispers = [
        "A distant song stirs\u{2026}",
        "Do you hear it\u{2026} a familiar melody\u{2026}",
        "The wind carries a golden note\u{2026}",
        "Something stirs among the branches\u{2026}",
        "A flutter of wings, drawing near\u{2026}",
        "The garden hums with anticipation\u{2026}",
    ]

    // Hint system
    @StateObject private var hintStore = GardenHintStore()
    @State private var hintVisible = false

    // Perch positions on land (cobblestone & garden bed, alternating left/right)
    private let nightingalePerchPositions: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.82),   // left cobblestone, near flower pot
        CGPoint(x: 0.55, y: 0.48),   // garden bed, center bush
        CGPoint(x: 0.22, y: 0.52),   // near the stairs
        CGPoint(x: 0.70, y: 0.45)    // garden bed, right side
    ]

    @State private var lastUpdateTime: Date?
    let timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("GardenView")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                Color(red: 1.0, green: 0.95, blue: 0.85)
                    .opacity(0.08 + breathingIntensity * 0.02)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.3)],
                    center: .center,
                    startRadius: geo.size.width * 0.3,
                    endRadius: geo.size.width * 0.7
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                WaterMetalView(bridge: waterBridge,
                               isActive: isActive,
                               reduceMotion: reduceMotion)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(PoolWaterHitShape())
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                PoolWaterHitShape()
                    .fill(.clear)
                    .contentShape(PoolWaterHitShape())
                    .onTapGesture { location in
                        handleTap(at: location, in: geo.size)
                    }
                    .accessibilityLabel("Garden pool")
                    .accessibilityHint("Double tap to create a lily pad")
                    .accessibilityAddTraits(.isButton)

                ForEach(pads) { pad in
                    renderPad(pad, in: geo.size)
                }

                // Nightingale hint glow — rendered BEHIND the bird so it looks backlit
                // effectsOpacity fades bright effects; vignette stays independent
                // Renders as soon as showNightingale is true (not just perched) so
                // the vignette crossfades with any non-nightingale invitation
                if showNightingale, hintVisible,
                   !showApproachFeather, !showApproachWhisper,
                   !showPoem, !showNightingaleCouplet {
                    let hintPos = hintPosition(for: .tapNightingale, in: geo.size)
                    let hintMode: GardenHintMode = (hintStore.activeHint == .tapNightingale) ? .tutorial : .invitation
                    GardenHintView(
                        stage: .tapNightingale,
                        targetPosition: hintPos,
                        screenSize: geo.size,
                        reduceMotion: reduceMotion,
                        mode: hintMode,
                        effectsOpacity: nightingaleGlowOpacity
                    )
                    .allowsHitTesting(false)
                }

                // Nightingale — rendered on top of its glow
                if showNightingale {
                    NightingaleView(
                        size: geo.size.width * 0.10,
                        isPerched: nightingaleIsPerched
                    )
                    .scaleEffect(x: nightingaleFacingRight ? 1 : -1,
                                 y: nightingaleCurrentWingPulse)
                    .rotationEffect(.degrees(nightingaleCurrentBodyAngle))
                    .position(nightingaleScreenPos(in: geo.size))
                    .opacity(nightingaleAppearOpacity)
                    .onTapGesture {
                        handleNightingaleTap(in: geo.size)
                    }
                }

                GardenParticleCanvas(petalBurst: petalBurst, reduceMotion: reduceMotion, isActive: isActive)

                ForEach(fireflies) { firefly in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.95, blue: 0.7).opacity(firefly.opacity),
                                    Color(red: 1.0, green: 0.9, blue: 0.6).opacity(firefly.opacity * 0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: firefly.size
                            )
                        )
                        .frame(width: firefly.size * 2, height: firefly.size * 2)
                        .position(firefly.position)
                }

                // Garden hints — tutorial (non-nightingale; nightingale renders behind the bird)
                if let stage = hintStore.activeHint, hintVisible,
                   stage != .tapNightingale,
                   !showApproachFeather, !showApproachWhisper {
                    GardenHintView(
                        stage: stage,
                        targetPosition: hintPosition(for: stage, in: geo.size),
                        screenSize: geo.size,
                        reduceMotion: reduceMotion,
                        mode: .tutorial
                    )
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                // Garden hints — persistent invitation glow (non-nightingale)
                // Hidden when nightingale is present — its own hint takes over
                if let invitation = invitationStage(in: geo.size), hintVisible,
                   invitation.stage != .tapNightingale, !showNightingale {
                    GardenHintView(
                        stage: invitation.stage,
                        targetPosition: invitation.position,
                        screenSize: geo.size,
                        reduceMotion: reduceMotion,
                        mode: .invitation
                    )
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                if let poem = currentPoem {
                    Color.black.opacity(showPoem ? 0.4 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            audio.playSFX(.poemDismiss)
                            Haptics.poemDismiss()
                            if reduceMotion {
                                withAnimation(.default) {
                                    showPoem = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentPoem = nil
                                    if poolPoemsSinceNightingale >= 3 && !showNightingale && !nightingaleInFlight {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            guard !nightingaleInFlight, !showNightingale else { return }
                                            nightingaleFlyIn()
                                        }
                                    } else {
                                        checkNightingaleApproachHint()
                                    }
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showPoem = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    currentPoem = nil
                                    if poolPoemsSinceNightingale >= 3 && !showNightingale && !nightingaleInFlight {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            guard !nightingaleInFlight, !showNightingale else { return }
                                            nightingaleFlyIn()
                                        }
                                    } else {
                                        checkNightingaleApproachHint()
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(showPoem)
                        .accessibilityLabel("Dismiss poem")
                        .accessibilityHint("Double tap to close")
                        .accessibilityAddTraits(.isButton)

                    PoemOverlayView(
                        poet: poem.poet,
                        persian: poem.persian,
                        english: poem.english,
                        culturalNote: poem.culturalNote,
                        reflection: poem.reflection
                    )
                    .opacity(showPoem ? 1 : 0)
                    .scaleEffect(showPoem ? 1 : 0.95)
                    .allowsHitTesting(false)
                }

                // Nightingale bonus couplet overlay
                if let couplet = currentNightingaleCouplet {
                    Color.black.opacity(showNightingaleCouplet ? 0.4 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            audio.playSFX(.poemDismiss)
                            Haptics.poemDismiss()
                            if reduceMotion {
                                withAnimation(.default) {
                                    showNightingaleCouplet = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentNightingaleCouplet = nil
                                    nightingaleDismiss()
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showNightingaleCouplet = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    currentNightingaleCouplet = nil
                                    nightingaleDismiss()
                                }
                            }
                        }
                        .allowsHitTesting(showNightingaleCouplet)
                        .accessibilityLabel("Dismiss couplet")
                        .accessibilityHint("Double tap to close")
                        .accessibilityAddTraits(.isButton)

                    PoemOverlayView(
                        poet: couplet.poet,
                        persian: couplet.persian,
                        english: couplet.english,
                        culturalNote: couplet.culturalNote,
                        reflection: couplet.reflection,
                        backgroundImage: "Katibe2"
                    )
                    .opacity(showNightingaleCouplet ? 1 : 0)
                    .scaleEffect(showNightingaleCouplet ? 1 : 0.95)
                    .allowsHitTesting(false)
                }

                // Nightingale departure whisper
                Color.black.opacity(0.3 * nightingaleWhisperOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Text(currentDepartureWhisper)
                    .font(.system(size: whisperSize, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(Color(red: 1.0, green: 0.92, blue: 0.65))
                    .shadow(color: .black.opacity(0.8), radius: 8)
                    .opacity(nightingaleWhisperOpacity)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.42)
                    .allowsHitTesting(false)

                // Golden feather + whisper — nightingale approaching hint
                if showApproachFeather || showApproachWhisper {
                    nightingaleApproachHintView(in: geo.size)
                        .allowsHitTesting(false)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("A golden feather descends — the nightingale draws near")
                }

            }
        }
        .ignoresSafeArea()
        .onAppear {
            loadGardenState()

            for _ in 0..<4 {
                spawnFirefly(screenSize: UIScreen.main.bounds.size, randomY: true)
            }

            // Show hints after a short delay so the scene establishes first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.6)) {
                    hintVisible = true
                }
            }
        }
        .onReceive(timer) { now in
            guard isActive else {
                lastUpdateTime = nil  // reset so no dt spike when resuming
                return
            }

            let dt: TimeInterval
            if let last = lastUpdateTime {
                dt = min(now.timeIntervalSince(last), 0.1)
            } else {
                dt = 1.0 / 60.0
            }
            lastUpdateTime = now
            time += dt
            updatePads(dt: dt)

            if reduceMotion {
                breathingIntensity = 0.5
            } else {
                breathingIntensity = sin(time * 0.3) * 0.5 + 0.5
                updateFireflies(dt: dt, screenSize: UIScreen.main.bounds.size)
            }

            // Timer-driven bounding flight — updated every frame
            if nightingaleInFlight, let startTime = nightingaleFlightStartTime {
                let elapsed = now.timeIntervalSince(startTime)
                nightingaleFlightT = CGFloat(min(elapsed / nightingaleFlightDuration, 1.0))
                if nightingaleFlightT >= 1.0 {
                    completeNightingaleFlight()
                }
            }
        }
    }

    private func renderPad(_ pad: Pad, in size: CGSize) -> some View {
        let padSize = size.width * 0.12
        let half = padSize / 2
        let rawX = pad.anchor.x * size.width
        let rawY = pad.anchor.y * size.height + pad.bobOffset
        let x = min(max(rawX, half), size.width - half)
        let y = min(max(rawY, half), size.height - half)

        return ZStack {
            if pad.isLotus && pad.glowIntensity > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.9, blue: 0.6).opacity(pad.glowIntensity * 0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: padSize * 0.8
                        )
                    )
                    .frame(width: padSize * 1.6, height: padSize * 1.6)
            }

            Image(pad.isLotus ? "LotusFull" : "LilyPad")
                .resizable()
                .scaledToFit()
                .frame(width: padSize, height: padSize)
        }
        .frame(width: padSize, height: padSize)
        .contentShape(Circle())
        .onTapGesture {
            handlePadTap(pad)
        }
        .allowsHitTesting(!pad.isLotus)
        .position(x: x, y: y)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0, anchor: .bottom).combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            )
        )
        .animation(.easeInOut(duration: 0.5), value: pad.isLotus)
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        // Block taps while another action is in progress
        guard !showPoem, !showNightingaleCouplet,
              !nightingaleInFlight, !showApproachFeather else { return }

        let normalized = CGPoint(x: location.x / size.width,
                                 y: location.y / size.height)
        let safePoint = pushInsidePool(normalized, margin: 0.07)

        // Remove oldest pad BEFORE finding spot, so we don't avoid a pad that's leaving
        if pads.count >= 5 {
            if reduceMotion {
                pads.removeFirst()
            } else {
                _ = withAnimation(.easeOut(duration: 0.3)) {
                    pads.removeFirst()
                }
            }
        }

        let separated = findNonOverlappingSpot(near: safePoint, screenSize: size)
        createLilyPad(at: separated)
        waterBridge.addRipple(at: normalized)
        audio.playSFX(.waterDrop)
        audio.playSFX(.lilyPadAppear)
        Haptics.waterTouch()
        petalBurst += 1
        bobNearbyPads(tapLocation: normalized)
        hintStore.markPoolTapped()
        hintStore.markPoolTappedAgain()
        hintStore.markPoolTappedThrice()
        saveGardenState()
    }

    /// Nudges a point toward the pool center until it's `margin` inside every edge.
    private func pushInsidePool(_ point: CGPoint, margin: CGFloat) -> CGPoint {
        if isPointInPoolPolygon(point, margin: margin) { return point }

        let center = CGPoint(x: 0.65, y: 0.82)
        var result = point
        for _ in 0..<20 {
            if isPointInPoolPolygon(result, margin: margin) { break }
            result = CGPoint(
                x: result.x + (center.x - result.x) * 0.15,
                y: result.y + (center.y - result.y) * 0.15
            )
        }
        return result
    }

    /// Minimum center-to-center pixel distance (pad diameter + quarter-pad gap).
    private func padMinPixels(_ screenSize: CGSize) -> CGFloat {
        let padPx = screenSize.width * 0.12
        return padPx * 1.25 // pad + quarter-pad gap
    }

    /// Euclidean pixel distance between two normalized points.
    private func pixelDistance(_ a: CGPoint, _ b: CGPoint, screenSize: CGSize) -> CGFloat {
        let dx = (a.x - b.x) * screenSize.width
        let dy = (a.y - b.y) * screenSize.height
        return sqrt(dx * dx + dy * dy)
    }

    /// Checks overlap using Euclidean pixel distance (accounts for aspect ratio).
    private func padsOverlapInPixels(_ a: CGPoint, _ b: CGPoint, screenSize: CGSize) -> Bool {
        pixelDistance(a, b, screenSize: screenSize) < padMinPixels(screenSize)
    }

    /// Finds the nearest position to `tap` that doesn't overlap any existing pad.
    /// Uses a fine grid search across the pool; falls back to the farthest-from-pads spot.
    private func findNonOverlappingSpot(near tap: CGPoint, screenSize: CGSize) -> CGPoint {
        // Quick check — tap position might already be clear
        if !pads.contains(where: { padsOverlapInPixels(tap, $0.anchor, screenSize: screenSize) }) {
            return tap
        }

        let minPx = padMinPixels(screenSize)
        var bestClearPoint: CGPoint? = nil
        var bestClearDist = CGFloat.infinity

        // Fallback: position whose minimum distance to any pad is largest
        var fallbackPoint = tap
        var fallbackMaxMinDist: CGFloat = -1

        let step: CGFloat = 0.01
        var y: CGFloat = 0.58
        while y <= 1.02 {
            var x: CGFloat = 0.18
            while x <= 1.08 {
                let candidate = CGPoint(x: x, y: y)
                guard isPointInPoolPolygon(candidate, margin: 0.07) else {
                    x += step; continue
                }

                // Minimum pixel distance to any existing pad
                var closestPadDist = CGFloat.infinity
                for pad in pads {
                    let d = pixelDistance(candidate, pad.anchor, screenSize: screenSize)
                    closestPadDist = min(closestPadDist, d)
                }

                // Track fallback (best spot even if not fully clear)
                if closestPadDist > fallbackMaxMinDist {
                    fallbackMaxMinDist = closestPadDist
                    fallbackPoint = candidate
                }

                // Clear spot — pick the one closest to the original tap
                if closestPadDist >= minPx {
                    let distToTap = pixelDistance(candidate, tap, screenSize: screenSize)
                    if distToTap < bestClearDist {
                        bestClearDist = distToTap
                        bestClearPoint = candidate
                    }
                }

                x += step
            }
            y += step
        }

        return bestClearPoint ?? fallbackPoint
    }

    private func updatePads(dt: TimeInterval) {
        let s = CGFloat(dt / 0.08)
        let screenSize = UIScreen.main.bounds.size
        let minPx = padMinPixels(screenSize)

        for index in pads.indices {
            // Vertical bob (spring-damper)
            if abs(pads[index].bobOffset) > 0.01 || abs(pads[index].bobVelocity) > 0.01 {
                pads[index].bobVelocity += -pads[index].bobOffset * 0.3 * s
                pads[index].bobVelocity *= pow(0.85, s)
                pads[index].bobOffset += pads[index].bobVelocity * s
            } else {
                pads[index].bobOffset = 0
                pads[index].bobVelocity = 0
            }

            if pads[index].glowIntensity > 0 {
                pads[index].glowIntensity = max(0, pads[index].glowIntensity - 0.015 * s)
            }

            // 1. Compute desired movement
            let movement = calculateMovement(for: pads[index], time: time)
            var dx = movement.x * s
            var dy = movement.y * s

            // 2. Pixel-space collision: cancel approach + gentle repulsion
            let current = pads[index].anchor
            for otherIndex in pads.indices where otherIndex != index {
                let other = pads[otherIndex].anchor
                let pxDist = pixelDistance(current, other, screenSize: screenSize)

                if pxDist < minPx && pxDist > 0.5 {
                    // Direction in pixel space
                    let dxPx = (other.x - current.x) * screenSize.width
                    let dyPx = (other.y - current.y) * screenSize.height
                    let nxPx = dxPx / pxDist
                    let nyPx = dyPx / pxDist

                    // Movement in pixel space
                    let movePxX = dx * screenSize.width
                    let movePxY = dy * screenSize.height

                    // Cancel approach component
                    let dot = movePxX * nxPx + movePxY * nyPx
                    if dot > 0 {
                        dx -= (dot * nxPx) / screenSize.width
                        dy -= (dot * nyPx) / screenSize.height
                    }

                    // Gentle repulsion to slowly separate any existing overlap
                    let overlap = minPx - pxDist
                    let repulsionPx = overlap * 0.02 * s
                    dx -= (nxPx * repulsionPx) / screenSize.width
                    dy -= (nyPx * repulsionPx) / screenSize.height
                }
            }

            // 3. Apply clamped movement (no sudden jumps)
            let maxStep: CGFloat = 0.003 * s
            let stepLen = sqrt(dx * dx + dy * dy)
            if stepLen > maxStep {
                let scale = maxStep / stepLen
                dx *= scale
                dy *= scale
            }

            let newPosition = CGPoint(x: current.x + dx, y: current.y + dy)

            if isPointInPool(newPosition) {
                pads[index].anchor = newPosition
            }

            // Pick a new wander target when close enough
            let distToTarget = distance(pads[index].anchor, pads[index].targetAnchor)
            if distToTarget < 0.04 || Int(time * 12) % 120 == index * 24 {
                pads[index].targetAnchor = randomPointInPool()
                if Double.random(in: 0...1) < 0.15 {
                    pads[index].movementStyle = MovementStyle.allCases.randomElement()!
                    pads[index].phase = CGFloat.random(in: 0...(2 * .pi))
                }
            }
        }
    }

    private func createLilyPad(at position: CGPoint) {
        guard let poem = revealedPoemsStore.getNextPoem() else { return }

        let newPad = Pad(
            anchor: position,
            isLotus: false,
            targetAnchor: randomPointInPool(),
            movementStyle: MovementStyle.allCases.randomElement()!,
            phase: CGFloat.random(in: 0...(2 * .pi)),
            speed: CGFloat.random(in: 0.7...1.2),
            storedPoem: poem
        )

        if reduceMotion {
            pads.append(newPad)
        } else {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                pads.append(newPad)
            }
        }
    }

    private func handlePadTap(_ pad: Pad) {
        // Block taps while another action is in progress
        guard !showPoem, !showNightingaleCouplet,
              !nightingaleInFlight, !showApproachFeather else { return }

        guard !pad.isLotus,
              let index = pads.firstIndex(where: { $0.id == pad.id }) else { return }

        pads[index].isLotus = true
        pads[index].glowIntensity = 1.0
        audio.playSFX(.lotusBloom)
        Haptics.lotusBloom()

        if let poem = pads[index].storedPoem {
            currentPoem = poem
            revealedPoemsStore.revealPoem(poem)
            audio.playSFX(.poemReveal)

            if reduceMotion {
                withAnimation(.default) {
                    showPoem = true
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                    showPoem = true
                }
            }

            petalBurst += 2
        }

        hintStore.markPadTapped()
        hintStore.markSecondPadTapped()
        hintStore.markThirdPadTapped()

        poolPoemsSinceNightingale += 1
        saveGardenState()
    }

    private func bobNearbyPads(tapLocation: CGPoint) {
        for index in pads.indices {
            let dist = distance(pads[index].anchor, tapLocation)
            if dist < 0.2 {
                let strength = (0.2 - dist) / 0.2
                pads[index].bobVelocity = -3.0 * strength
            }
        }
    }

    // MARK: - Nightingale

    private func nightingaleFlyIn() {
        audio.playSFX(.wingFlutter)

        nightingalePerchIndex = (nightingalePerchIndex + 1) % nightingalePerchPositions.count
        let destination = nightingalePerchPositions[nightingalePerchIndex]

        let enterFromRight = destination.x < 0.5
        let enterX: CGFloat = enterFromRight ? 1.15 : -0.15
        let enterY: CGFloat = destination.y - 0.10
        nightingaleFacingRight = !enterFromRight

        nightingaleIsPerched = false
        nightingaleIsFlyingOut = false
        nightingaleGlowOpacity = 0

        if reduceMotion {
            showNightingale = true
            nightingalePosition = destination
            nightingaleIsPerched = true
            nightingaleAppearOpacity = 1
            nightingaleGlowOpacity = 1
        } else {
            // Instant swap — nightingale vignette replaces non-nightingale in same frame
            showNightingale = true
            nightingaleFlightOrigin = CGPoint(x: enterX, y: enterY)
            nightingaleFlightDest = destination
            nightingaleFlightT = 0
            nightingaleFlightDuration = 2.6
            nightingaleFlightStartTime = Date()
            nightingaleInFlight = true
            nightingaleAppearOpacity = 0

            // Fade in gently
            withAnimation(.easeIn(duration: 0.6)) {
                nightingaleAppearOpacity = 1
            }
        }
    }

    private func handleNightingaleTap(in size: CGSize) {
        guard nightingaleIsPerched,
              !nightingaleInFlight,
              !showPoem,
              !showNightingaleCouplet,
              !showApproachFeather else { return }

        hintStore.markNightingaleTapped()
        audio.playSFX(.nightingaleFarewell)
        audio.playSFX(.wingDeparture)
        Haptics.nightingaleTap()
        nightingaleIsPerched = false

        // Fade out holy light as the bird takes off
        withAnimation(.easeOut(duration: 0.6)) {
            nightingaleGlowOpacity = 0
        }

        let startPos = nightingalePosition
        let flyOutRight = startPos.x < 0.5
        let exitX: CGFloat = flyOutRight ? 1.15 : -0.15
        nightingaleFacingRight = flyOutRight

        if reduceMotion {
            nightingaleAppearOpacity = 0
            showBonusCouplet()
        } else {
            petalBurst += 1
            nightingaleIsFlyingOut = true
            nightingaleFlightOrigin = startPos
            nightingaleFlightDest = CGPoint(x: exitX, y: startPos.y - 0.08)
            nightingaleFlightT = 0
            nightingaleFlightDuration = 2.2
            nightingaleFlightStartTime = Date()
            nightingaleInFlight = true

            // Fade out gently in the second half
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeIn(duration: 1.1)) {
                    nightingaleAppearOpacity = 0
                }
            }
        }
    }

    private func checkNightingaleApproachHint() {
        guard poolPoemsSinceNightingale == 2,
              !showApproachFeather else { return }

        // Pick approach whisper for this cycle
        currentApproachWhisper = approachWhispers[
            nightingaleCoupletIndex % approachWhispers.count
        ]

        if reduceMotion {
            // Just show the whisper text
            withAnimation(.easeIn(duration: 0.5)) {
                showApproachWhisper = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showApproachWhisper = false
                }
            }
        } else {
            triggerNightingaleApproachHint()
        }
    }

    private func triggerNightingaleApproachHint() {
        audio.playSFX(.whisperTone)
        showApproachFeather = true
        featherFallProgress = 0
        featherOpacity = 0

        // Feather fades in gently
        withAnimation(.easeIn(duration: 0.8)) {
            featherOpacity = 1.0
        }
        // Linear fall over 4.5 seconds — graceful but purposeful
        withAnimation(.linear(duration: 4.5)) {
            featherFallProgress = 1.0
        }

        // Whisper text appears mid-fall
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.6)) {
                showApproachWhisper = true
            }
        }

        // Feather fades out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeOut(duration: 1.5)) {
                featherOpacity = 0
            }
        }

        // Whisper fades out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            withAnimation(.easeOut(duration: 1.0)) {
                showApproachWhisper = false
            }
        }

        // Reset feather state — after everything has fully faded
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            showApproachFeather = false
            featherFallProgress = 0
        }
    }

    @ViewBuilder
    private func nightingaleApproachHintView(in size: CGSize) -> some View {
        // --- Feather dancing with the wind ---
        // Layered sinusoids at irrational frequency ratios = organic, never-repeating motion
        let t = Double(featherFallProgress)
        let time = t * 4.5

        let buildUp = min(1.0, time / 1.0)

        // Lateral sway: three overlapping waves at irrational ratios
        // Creates an unpredictable drift — sometimes wide, sometimes tight
        let sway1 = sin(2.0 * .pi * 0.45 * time)               // slow base
        let sway2 = sin(2.0 * .pi * 0.45 * 1.618 * time) * 0.5 // golden ratio
        let sway3 = sin(2.0 * .pi * 0.45 * 0.73 * time) * 0.35 // slow modulation
        let swayAmplitude: CGFloat = size.width * 0.13 * CGFloat(buildUp)
        let swayX = CGFloat(sway1 + sway2 + sway3) * swayAmplitude / 1.85

        let baseX = size.width * 0.48

        // Vertical: slow descent with irregular bobbing
        let startY: CGFloat = -40
        let endY: CGFloat = size.height * 0.65
        let baseY = startY + (endY - startY) * CGFloat(t)
        // Two lift frequencies: feather hesitates and floats at irregular intervals
        let lift1 = cos(2.0 * .pi * 0.72 * time) * 6.0
        let lift2 = cos(2.0 * .pi * 0.45 * time) * 4.0
        let currentY = baseY + CGFloat(lift1 + lift2) * CGFloat(buildUp)

        // Rotation: feather tumbles and dances — NOT always pointing down
        // Three layered rotations create a complex, wind-blown tumble
        let rot1 = 50.0 * sin(2.0 * .pi * 0.45 * time)                // wide sweep
        let rot2 = 40.0 * sin(2.0 * .pi * 0.45 * 1.618 * time)       // golden ratio offset
        let rot3 = 25.0 * sin(2.0 * .pi * 0.45 * 2.247 * time)       // faster flutter
        let rotation = (rot1 + rot2 + rot3) * buildUp

        let gold = Color(red: 1.0, green: 0.92, blue: 0.65)
        let warmGold = Color(red: 1.0, green: 0.85, blue: 0.45)

        ZStack {
            // Deep dim overlay — isolates the moment
            if showApproachFeather {
                Color.black
                    .opacity(0.45 * featherOpacity)
                    .ignoresSafeArea()
            }

            // Golden light cone
            if showApproachFeather {
                let apexX = size.width * 0.48
                let beamLeft = size.width * 0.08
                let beamRight = size.width * 0.88
                let beamBottom = size.height * 0.70

                // Outer soft cone
                Path { path in
                    path.move(to: CGPoint(x: apexX, y: -20))
                    path.addLine(to: CGPoint(x: beamLeft, y: beamBottom))
                    path.addLine(to: CGPoint(x: beamRight, y: beamBottom))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            warmGold.opacity(0.30),
                            gold.opacity(0.14),
                            gold.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 24)
                .opacity(featherOpacity)
                .ignoresSafeArea()

                // Inner bright cone
                Path { path in
                    path.move(to: CGPoint(x: apexX, y: -20))
                    path.addLine(to: CGPoint(x: size.width * 0.28, y: beamBottom * 0.85))
                    path.addLine(to: CGPoint(x: size.width * 0.68, y: beamBottom * 0.85))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            warmGold.opacity(0.10),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 14)
                .opacity(featherOpacity)
                .ignoresSafeArea()

                // Bright source glow at apex
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        warmGold.opacity(0.25),
                        gold.opacity(0.10),
                        Color.clear
                    ],
                    center: UnitPoint(x: apexX / size.width, y: 0),
                    startRadius: 0,
                    endRadius: size.height * 0.24
                )
                .opacity(featherOpacity)
                .ignoresSafeArea()
            }

            // Feather with physics-based motion
            if showApproachFeather {
                ZStack {
                    // Outer warm halo — follows the feather
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    warmGold.opacity(0.28),
                                    gold.opacity(0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Inner bright glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.30),
                                    warmGold.opacity(0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)

                    // The feather itself — layered rendering
                    ZStack {
                        // Vane fill — rich golden gradient with subtle warmth variation
                        FeatherShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.97, blue: 0.78),
                                        Color(red: 1.0, green: 0.92, blue: 0.58),
                                        Color(red: 0.95, green: 0.82, blue: 0.42),
                                        warmGold,
                                        Color(red: 0.82, green: 0.65, blue: 0.28)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Inner vane shading — subtle darker tone on the wider side
                        FeatherShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color(red: 0.78, green: 0.58, blue: 0.20).opacity(0.12),
                                        Color(red: 0.72, green: 0.50, blue: 0.15).opacity(0.18),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        // Barb texture — fine lines from rachis
                        FeatherBarbs()
                            .stroke(
                                Color(red: 0.80, green: 0.62, blue: 0.24).opacity(0.30),
                                lineWidth: 0.6
                            )

                        // Rachis — dark golden shaft with taper
                        FeatherRachis()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.70, green: 0.52, blue: 0.18).opacity(0.8),
                                        Color(red: 0.76, green: 0.58, blue: 0.22).opacity(0.6),
                                        Color(red: 0.65, green: 0.46, blue: 0.14).opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
                            )

                        // Light-catching edge highlight
                        FeatherShape()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.45),
                                        warmGold.opacity(0.25),
                                        Color.clear,
                                        warmGold.opacity(0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.7
                            )

                        // Calamus highlight — pale translucent quill base
                        FeatherCalamus()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.15),
                                        Color(red: 0.95, green: 0.90, blue: 0.75).opacity(0.25)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .frame(width: 32, height: 70)
                    .shadow(color: warmGold.opacity(0.7), radius: 12)
                }
                .rotationEffect(.degrees(rotation))
                .position(x: baseX + swayX, y: currentY)
                .opacity(featherOpacity)
            }

            // Whisper text
            if showApproachWhisper {
                Text(currentApproachWhisper)
                    .font(.system(size: approachWhisperSize, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: warmGold.opacity(0.4), radius: 12)
                    .shadow(color: .black.opacity(0.8), radius: 6)
                    .position(x: size.width * 0.5, y: size.height * 0.55)
                    .transition(.opacity)
            }
        }
    }

    private func nightingaleDismiss() {
        audio.playSFX(.whisperTone)

        // Fade out holy light gracefully, then remove the nightingale
        withAnimation(.easeOut(duration: 1.2)) {
            nightingaleGlowOpacity = 0
            nightingaleAppearOpacity = 0
        }
        nightingaleIsPerched = true
        poolPoemsSinceNightingale = 0
        saveGardenState()

        // After effects fade out, instant swap back to non-nightingale invitation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            showNightingale = false
        }

        // Departure whisper — cycles through different lines (safe modulo)
        let whisperIdx = (nightingaleCoupletIndex + departureWhispers.count - 1) % departureWhispers.count
        currentDepartureWhisper = departureWhispers[whisperIdx]
        withAnimation(.easeIn(duration: 0.8)) {
            nightingaleWhisperOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 1.2)) {
                nightingaleWhisperOpacity = 0
            }
        }
    }

    // MARK: - Nightingale Sprite (computed position/rotation during flight)

    private func nightingaleScreenPos(in size: CGSize) -> CGPoint {
        if nightingaleInFlight {
            let raw = nightingaleIsFlyingOut
                ? nightingaleFlyOutPos(t: nightingaleFlightT)
                : nightingaleFlyInPos(t: nightingaleFlightT)
            return CGPoint(x: raw.x * size.width, y: raw.y * size.height)
        }
        return CGPoint(x: nightingalePosition.x * size.width,
                       y: nightingalePosition.y * size.height)
    }

    private var nightingaleCurrentBodyAngle: Double {
        nightingaleInFlight ? nightingaleBodyAngle(t: nightingaleFlightT) : 0
    }

    private var nightingaleCurrentWingPulse: CGFloat {
        nightingaleInFlight ? nightingaleWingPulse(t: nightingaleFlightT) : 1
    }

    // MARK: - Bounding Flight Path
    //
    // Smooth passerine flight — gentle undulating arc with soft body tilt.
    // Prioritizes calming, flowing motion over mechanical accuracy.
    // Pure sine bounding (3 gentle cycles), wide numerical derivative window
    // for buttery body rotation, no tremor, minimal wing pulse.

    /// Fly-in: off-screen → perch, 3 gentle bounding cycles over a sweeping arc
    private func nightingaleFlyInPos(t: CGFloat) -> CGPoint {
        let o = nightingaleFlightOrigin
        let d = nightingaleFlightDest

        // --- Horizontal: smooth ease-in-out ---
        let tEase = t * t * (3 - 2 * t)   // smoothstep — very gentle acceleration/deceleration
        let baseX = o.x + (d.x - o.x) * tEase

        // Soft lateral drift — one slow sine, nothing sharp
        let drift = sin(2 * .pi * 1.618 * t) * 0.005 * sin(.pi * t)
        let x = baseX + drift

        // --- Vertical: sweeping arc with soft bounding ---
        let arcPeak: CGFloat = 0.18
        let baseY = o.y + (d.y - o.y) * tEase - arcPeak * sin(.pi * t)

        // Gentle bounding: pure sine, 3 cycles, soft amplitude envelope
        let numBounds: CGFloat = 3
        let wave = sin(2 * .pi * numBounds * t)

        // Envelope: slow build → sustain → long smooth fade for landing
        let boundAmp: CGFloat = 0.026
        let env: CGFloat
        if t < 0.15 {
            let s = t / 0.15; env = s * s * (3 - 2 * s)       // smoothstep in
        } else if t < 0.60 {
            env = 1.0
        } else {
            let s = (t - 0.60) / 0.40; env = 1.0 - s * s      // quadratic fade
        }

        return CGPoint(x: x, y: baseY + boundAmp * env * wave)
    }

    /// Fly-out: perch → off-screen, gentle rise then flowing cruise
    private func nightingaleFlyOutPos(t: CGFloat) -> CGPoint {
        let o = nightingaleFlightOrigin
        let d = nightingaleFlightDest

        // --- Horizontal: gentle ease-in ---
        let tEase: CGFloat
        if t < 0.25 {
            // Slow start — bird lifts first, drifts second
            let s = t / 0.25
            tEase = s * s * 0.08                              // barely moves laterally
        } else {
            let s = (t - 0.25) / 0.75
            tEase = 0.08 + s * s * (3 - 2 * s) * 0.92        // smoothstep cruise
        }
        let baseX = o.x + (d.x - o.x) * tEase

        let drift = sin(2 * .pi * 2.17 * t) * 0.004 * sin(.pi * t)
        let x = baseX + drift

        // --- Vertical: graceful rise then gentle descent ---
        let climbHeight: CGFloat = 0.20
        let baseY: CGFloat
        if t < 0.28 {
            // Smooth rise
            let s = t / 0.28
            let easedLift = s * s * (3 - 2 * s)              // smoothstep climb
            baseY = o.y - climbHeight * easedLift
        } else {
            // Gentle descent toward exit
            let s = (t - 0.28) / 0.72
            let peakY = o.y - climbHeight
            baseY = peakY + (d.y - peakY) * s * s * (3 - 2 * s)
        }

        // Soft bounding: 3 cycles
        let numBounds: CGFloat = 3
        let wave = sin(2 * .pi * numBounds * t)

        let boundAmp: CGFloat = 0.020
        let env: CGFloat
        if t < 0.22 {
            let s = t / 0.22; env = s * s                     // gentle build
        } else if t < 0.82 {
            env = 1.0
        } else {
            let s = (t - 0.82) / 0.18; env = 1.0 - s * s
        }

        return CGPoint(x: x, y: baseY + boundAmp * env * wave)
    }

    /// Body angle: smooth path-following tilt, no tremor
    private func nightingaleBodyAngle(t: CGFloat) -> Double {
        // Wide derivative window → very smooth angle changes
        let dt: CGFloat = 0.025
        let p1 = nightingaleIsFlyingOut
            ? nightingaleFlyOutPos(t: max(0, t - dt))
            : nightingaleFlyInPos(t: max(0, t - dt))
        let p2 = nightingaleIsFlyingOut
            ? nightingaleFlyOutPos(t: min(1, t + dt))
            : nightingaleFlyInPos(t: min(1, t + dt))

        let dx = abs(p2.x - p1.x)
        let dy = p2.y - p1.y
        let rawPitch = atan2(dy, max(dx, 0.0001)) * 180 / .pi

        // Gentle clamp — nothing extreme
        var angle = max(-25.0, min(25.0, rawPitch))

        // Soft landing pitch-up (last 22%)
        if !nightingaleIsFlyingOut && t > 0.78 {
            let s = Double(t - 0.78) / 0.22
            let smooth = s * s * (3 - 2 * s)
            angle = angle * (1 - smooth) + (-10.0) * smooth
        }

        // Gentle takeoff tilt (first 25%)
        if nightingaleIsFlyingOut && t < 0.25 {
            let s = 1.0 - Double(t) / 0.25
            let smooth = s * s * (3 - 2 * s)
            angle = angle * (1 - smooth) + (-20.0) * smooth
        }

        return nightingaleFacingRight ? angle : -angle
    }

    /// Subtle wing pulse — barely there, just a breath of life
    private func nightingaleWingPulse(t: CGFloat) -> CGFloat {
        let numBounds: CGFloat = nightingaleIsFlyingOut ? 3 : 3
        let wave = sin(2 * .pi * numBounds * t)

        // Gentle breathing: 0.97 – 1.02
        let pulse = 1.0 - 0.025 * wave

        let env: CGFloat
        if t < 0.10 { let s = t / 0.10; env = s * s }
        else if t > 0.90 { let s = (1 - t) / 0.10; env = s * s }
        else { env = 1.0 }

        return 1.0 + (pulse - 1.0) * env
    }

    /// Called by the timer when flight reaches t ≥ 1.0
    private func completeNightingaleFlight() {
        nightingaleInFlight = false
        nightingaleFlightStartTime = nil

        if nightingaleIsFlyingOut {
            showBonusCouplet()
        } else {
            // Landing: slight downward bob from weight, then spring settle
            let dest = nightingaleFlightDest
            nightingalePosition = CGPoint(x: dest.x, y: dest.y + 0.006)
            Haptics.nightingaleLanding()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                nightingalePosition = dest
            }
            // Holy light begins rising as the bird settles
            withAnimation(.easeIn(duration: 2.5)) {
                nightingaleGlowOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                nightingaleIsPerched = true
                petalBurst += 1
                audio.playSFX(.nightingaleChirp)
            }
        }
    }

    private func showBonusCouplet() {
        audio.playSFX(.poemReveal)
        Haptics.lotusBloom()
        let couplet = NightingaleCouplets.couplets[nightingaleCoupletIndex % NightingaleCouplets.couplets.count]
        nightingaleCoupletIndex += 1
        saveGardenState()
        currentNightingaleCouplet = couplet
        revealedPoemsStore.revealNightingaleCouplet(couplet)

        if reduceMotion {
            withAnimation(.default) {
                showNightingaleCouplet = true
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                showNightingaleCouplet = true
            }
        }
    }

    private func hintPosition(for stage: GardenHintStage, in size: CGSize) -> CGPoint {
        switch stage {
        case .tapPool, .tapPoolAgain, .tapPoolThrice:
            return CGPoint(x: 0.70 * size.width, y: 0.82 * size.height)
        case .tapLilyPad, .tapSecondLilyPad, .tapThirdLilyPad:
            if let firstPad = pads.first(where: { !$0.isLotus }) {
                return CGPoint(x: firstPad.anchor.x * size.width,
                               y: firstPad.anchor.y * size.height)
            }
            return CGPoint(x: 0.70 * size.width, y: 0.82 * size.height)
        case .tapNightingale:
            // During fly-in, use destination so the vignette prepares the landing spot
            let pos = (nightingaleInFlight && !nightingaleIsFlyingOut)
                ? nightingaleFlightDest
                : nightingalePosition
            return CGPoint(x: pos.x * size.width, y: pos.y * size.height)
        }
    }

    private func invitationStage(in size: CGSize) -> (stage: GardenHintStage, position: CGPoint)? {
        guard hintStore.isTutorialComplete else { return nil }
        guard !showPoem, !showNightingaleCouplet else { return nil }

        if showNightingale && nightingaleIsPerched {
            return (.tapNightingale, hintPosition(for: .tapNightingale, in: size))
        }
        // Suppress pool/lily invitation when nightingale arrival is imminent or in flight
        guard !nightingaleInFlight, poolPoemsSinceNightingale < 3 else { return nil }
        if pads.contains(where: { !$0.isLotus }) {
            return (.tapLilyPad, hintPosition(for: .tapLilyPad, in: size))
        }
        return (.tapPool, hintPosition(for: .tapPool, in: size))
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    private func randomPointInPool() -> CGPoint {
        var point: CGPoint
        var attempts = 0

        repeat {
            let x = CGFloat.random(in: 0.52...0.75)
            let y = CGFloat.random(in: 0.77...0.85)
            point = CGPoint(x: x, y: y)
            attempts += 1
        } while !isPointInPoolPolygon(point, margin: 0.10) && attempts < 50

        return attempts < 50 ? point : CGPoint(x: 0.63, y: 0.81)
    }

    private func isPointInPool(_ point: CGPoint) -> Bool {
        return isPointInPoolPolygon(point, margin: 0.10)
    }

    private func isPointInPoolPolygon(_ point: CGPoint, margin: CGFloat) -> Bool {
        let poolVertices: [CGPoint] = [
            CGPoint(x: 0.53, y: 0.65),
            CGPoint(x: 1.1, y: 0.73),
            CGPoint(x: 1.0, y: 1.01),
            CGPoint(x: 0.67, y: 0.92),
            CGPoint(x: 0.21, y: 0.8)
        ]

        let shrunkenVertices = shrinkPolygon(poolVertices, by: margin)

        var inside = false
        var j = shrunkenVertices.count - 1

        for i in 0..<shrunkenVertices.count {
            let vi = shrunkenVertices[i]
            let vj = shrunkenVertices[j]

            if ((vi.y > point.y) != (vj.y > point.y)) &&
               (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x) {
                inside.toggle()
            }
            j = i
        }

        return inside
    }

    private func shrinkPolygon(_ vertices: [CGPoint], by margin: CGFloat) -> [CGPoint] {
        let centroid = vertices.reduce(CGPoint.zero) {
            CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)
        }
        let center = CGPoint(
            x: centroid.x / CGFloat(vertices.count),
            y: centroid.y / CGFloat(vertices.count)
        )

        return vertices.map { vertex in
            let dx = center.x - vertex.x
            let dy = center.y - vertex.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance > 0 {
                let ratio = margin / distance
                return CGPoint(
                    x: vertex.x + dx * ratio,
                    y: vertex.y + dy * ratio
                )
            }
            return vertex
        }
    }


    private func spawnFirefly(screenSize: CGSize, randomY: Bool = false) {
        let baseOp = Double.random(in: 0.4...0.7)
        let firefly = Firefly(
            position: CGPoint(
                x: CGFloat.random(in: 0...screenSize.width),
                y: randomY ? CGFloat.random(in: screenSize.height * 0.3...screenSize.height) : screenSize.height + 20
            ),
            size: CGFloat.random(in: 3...6),
            opacity: baseOp,
            baseOpacity: baseOp,
            twinklePhase: CGFloat.random(in: 0...(2 * .pi)),
            speed: CGFloat.random(in: 0.15...0.35),
            drift: CGFloat.random(in: -0.4...0.4)
        )
        fireflies.append(firefly)

        if fireflies.count > 8 {
            fireflies.removeFirst()
        }
    }

    private func updateFireflies(dt: TimeInterval, screenSize: CGSize) {
        let s = CGFloat(dt / 0.08)

        for index in fireflies.indices {
            fireflies[index].position.y -= fireflies[index].speed * s
            let sway = sin(time * 0.3 + CGFloat(index) * 0.4) * 0.6
            fireflies[index].position.x += (fireflies[index].drift + sway) * s

            let twinkle = sin(time * 2 + fireflies[index].twinklePhase) * 0.5 + 0.5
            fireflies[index].opacity = fireflies[index].baseOpacity * (0.5 + twinkle * 0.5)

            if fireflies[index].position.y < -50 {
                let baseOp = Double.random(in: 0.4...0.7)
                fireflies[index] = Firefly(
                    position: CGPoint(x: CGFloat.random(in: 0...screenSize.width), y: screenSize.height + 20),
                    size: CGFloat.random(in: 3...6),
                    opacity: baseOp,
                    baseOpacity: baseOp,
                    twinklePhase: CGFloat.random(in: 0...(2 * .pi)),
                    speed: CGFloat.random(in: 0.15...0.35),
                    drift: CGFloat.random(in: -0.4...0.4)
                )
            }
        }
    }

    private func calculateMovement(for pad: Pad, time: TimeInterval) -> CGPoint {
        let baseSpeed: CGFloat = 0.0003 * pad.speed

        switch pad.movementStyle {
        case .gentle:
            let driftAngle = sin(time * 0.1 + pad.phase) * .pi
            let dx = cos(driftAngle) * baseSpeed * 2.5 + (pad.targetAnchor.x - pad.anchor.x) * baseSpeed * 1.5
            let dy = sin(driftAngle) * baseSpeed * 2.5 + (pad.targetAnchor.y - pad.anchor.y) * baseSpeed * 1.5
            return CGPoint(x: dx, y: dy)

        case .wavy:
            let waveX = sin(time * pad.speed * 0.4 + pad.phase) * baseSpeed * 2.5
            let waveY = cos(time * pad.speed * 0.3 + pad.phase) * baseSpeed * 2.5
            let driftX = sin(time * 0.08 + pad.phase * 2) * baseSpeed * 1.5
            let driftY = cos(time * 0.06 + pad.phase * 3) * baseSpeed * 1.5
            return CGPoint(x: waveX + driftX, y: waveY + driftY)

        case .circular:
            let angle = time * pad.speed * 0.3 + pad.phase
            let wanderX = sin(time * 0.05 + pad.phase) * baseSpeed * 1
            let wanderY = cos(time * 0.04 + pad.phase * 2) * baseSpeed * 1
            return CGPoint(
                x: cos(angle) * baseSpeed * 2.5 + wanderX,
                y: sin(angle) * baseSpeed * 2.5 + wanderY
            )

        case .zigzag:
            let t = time * pad.speed * 0.3 + pad.phase
            let zigX = sin(t) * baseSpeed * 3
            let zigY = sin(t * 2) * baseSpeed * 2
            let driftX = cos(time * 0.07 + pad.phase) * baseSpeed * 1
            let driftY = sin(time * 0.05 + pad.phase * 1.5) * baseSpeed * 1
            return CGPoint(x: zigX + driftX, y: zigY + driftY)

        case .stillness:
            let dx = sin(time * 0.2 + pad.phase) * baseSpeed * 1.5
            let dy = cos(time * 0.15 + pad.phase) * baseSpeed * 1.5
            return CGPoint(x: dx, y: dy)
        }
    }

    // MARK: - Garden State Persistence

    private static let gardenPadsKey = "garden_saved_pads"
    private static let nightingaleCoupletIndexKey = "garden_nightingale_couplet_index"
    private static let poolPoemsSinceNightingaleKey = "garden_pool_poems_since_nightingale"
    private static let nightingalePerchIndexKey = "garden_nightingale_perch_index"

    private func saveGardenState() {
        let saved = pads.map { pad in
            SavedPad(
                anchorX: pad.anchor.x,
                anchorY: pad.anchor.y,
                isLotus: pad.isLotus,
                movementStyle: pad.movementStyle,
                phase: pad.phase,
                speed: pad.speed,
                storedPoemID: pad.storedPoem?.id.uuidString
            )
        }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.gardenPadsKey)
        }
        UserDefaults.standard.set(nightingaleCoupletIndex, forKey: Self.nightingaleCoupletIndexKey)
        UserDefaults.standard.set(poolPoemsSinceNightingale, forKey: Self.poolPoemsSinceNightingaleKey)
        UserDefaults.standard.set(nightingalePerchIndex, forKey: Self.nightingalePerchIndexKey)
    }

    private func loadGardenState() {
        // Restore nightingale counters
        nightingaleCoupletIndex = UserDefaults.standard.integer(forKey: Self.nightingaleCoupletIndexKey)
        poolPoemsSinceNightingale = UserDefaults.standard.integer(forKey: Self.poolPoemsSinceNightingaleKey)
        nightingalePerchIndex = UserDefaults.standard.integer(forKey: Self.nightingalePerchIndexKey)

        // Restore pads
        guard let data = UserDefaults.standard.data(forKey: Self.gardenPadsKey),
              let savedPads = try? JSONDecoder().decode([SavedPad].self, from: data),
              !savedPads.isEmpty else { return }

        // Build lookup from all poems (library + nightingale couplets)
        let allPoems = PoemLibrary.poems + NightingaleCouplets.couplets
        let poemByID: [String: Poem] = Dictionary(
            allPoems.map { ($0.id.uuidString, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        pads = savedPads.compactMap { saved in
            let poem: Poem? = saved.storedPoemID.flatMap { poemByID[$0] }
            // Drop non-lotus pads whose poem was removed (they'd do nothing on tap)
            if !saved.isLotus && poem == nil { return nil }
            return Pad(
                anchor: CGPoint(x: saved.anchorX, y: saved.anchorY),
                isLotus: saved.isLotus,
                targetAnchor: randomPointInPool(),
                movementStyle: saved.movementStyle,
                phase: saved.phase,
                speed: saved.speed,
                storedPoem: poem
            )
        }
    }
}

/// Anatomically-informed nightingale contour feather.
/// Tip at top (y = 0), calamus at bottom (y = h).
/// Asymmetric vanes: inner (right) ~1.5x wider than outer (left).
/// Gently curved rachis offset toward the narrower outer vane.
/// Wispy downy barbs near the calamus, smooth vane above.
struct FeatherShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        // Rachis landmarks (gently curved, offset toward outer/left)
        let rachisX: CGFloat = w * 0.38
        let tipX: CGFloat = rachisX + w * 0.02
        let vaneStartY: CGFloat = h * 0.80
        let widestY: CGFloat = h * 0.36
        let calamousBottom = CGPoint(x: rachisX, y: h)

        // Vane widths
        let outerVaneMax: CGFloat = w * 0.26
        let innerVaneMax: CGFloat = w * 0.44

        // Key points
        let outerAtWidest = CGPoint(x: rachisX - outerVaneMax, y: widestY)
        let outerAtVaneStart = CGPoint(x: rachisX - w * 0.03, y: vaneStartY)
        let innerAtWidest = CGPoint(x: rachisX + innerVaneMax, y: widestY + h * 0.04)
        let innerAtVaneStart = CGPoint(x: rachisX + w * 0.05, y: vaneStartY)

        var path = Path()

        // === TIP (slightly asymmetric, off-center toward outer vane) ===
        path.move(to: CGPoint(x: tipX, y: 0))

        // === OUTER VANE (left, narrower, tighter curvature) ===
        // Tip → shoulder: gentle outward curve
        path.addCurve(
            to: outerAtWidest,
            control1: CGPoint(x: tipX - w * 0.16, y: h * 0.08),
            control2: CGPoint(x: rachisX - outerVaneMax - w * 0.01, y: h * 0.20)
        )
        // Shoulder → lower vane: with subtle natural waviness
        path.addCurve(
            to: CGPoint(x: rachisX - w * 0.14, y: h * 0.58),
            control1: CGPoint(x: rachisX - outerVaneMax + w * 0.01, y: h * 0.45),
            control2: CGPoint(x: rachisX - w * 0.18, y: h * 0.52)
        )
        // Lower vane → wispy transition zone
        path.addCurve(
            to: outerAtVaneStart,
            control1: CGPoint(x: rachisX - w * 0.10, y: h * 0.65),
            control2: CGPoint(x: rachisX - w * 0.06, y: h * 0.74)
        )

        // === CALAMUS (outer side) — narrow translucent quill ===
        let calamousHalfW: CGFloat = w * 0.016
        path.addCurve(
            to: calamousBottom,
            control1: CGPoint(x: rachisX - calamousHalfW * 1.8, y: h * 0.87),
            control2: CGPoint(x: rachisX - calamousHalfW, y: h * 0.95)
        )

        // === CALAMUS (inner side) — back up ===
        path.addCurve(
            to: innerAtVaneStart,
            control1: CGPoint(x: rachisX + calamousHalfW, y: h * 0.95),
            control2: CGPoint(x: rachisX + calamousHalfW * 1.8, y: h * 0.87)
        )

        // === INNER VANE (right, wider, softer curvature) ===
        // Wispy transition → lower vane
        path.addCurve(
            to: CGPoint(x: rachisX + w * 0.30, y: h * 0.56),
            control1: CGPoint(x: rachisX + w * 0.09, y: h * 0.74),
            control2: CGPoint(x: rachisX + w * 0.22, y: h * 0.65)
        )
        // Lower vane → widest (fuller bow)
        path.addCurve(
            to: innerAtWidest,
            control1: CGPoint(x: rachisX + w * 0.38, y: h * 0.48),
            control2: CGPoint(x: rachisX + innerVaneMax + w * 0.02, y: h * 0.42)
        )
        // Widest → tip (sweeps back, tip offset toward outer vane)
        path.addCurve(
            to: CGPoint(x: tipX, y: 0),
            control1: CGPoint(x: rachisX + innerVaneMax + w * 0.01, y: h * 0.18),
            control2: CGPoint(x: tipX + w * 0.24, y: h * 0.06)
        )

        path.closeSubpath()
        return path
    }
}

/// The rachis (central shaft) — gentle S-curve from calamus to tip.
struct FeatherRachis: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let rachisX: CGFloat = w * 0.38
        let tipX: CGFloat = rachisX + w * 0.02

        var path = Path()
        path.move(to: CGPoint(x: rachisX, y: h))

        // S-curve: slight left bias low, straightens, slight right near tip
        path.addCurve(
            to: CGPoint(x: rachisX - w * 0.005, y: h * 0.55),
            control1: CGPoint(x: rachisX - w * 0.008, y: h * 0.85),
            control2: CGPoint(x: rachisX - w * 0.012, y: h * 0.68)
        )
        path.addCurve(
            to: CGPoint(x: tipX, y: 0),
            control1: CGPoint(x: rachisX + w * 0.008, y: h * 0.35),
            control2: CGPoint(x: tipX + w * 0.005, y: h * 0.12)
        )
        return path
    }
}

/// Barb lines radiating from the rachis. Angle varies: shallow near tip, steep near base.
/// Includes wispy downy barbs near the calamus.
struct FeatherBarbs: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let rachisX: CGFloat = w * 0.38

        var path = Path()

        // Main vane barbs (clean, structured)
        let barbCount = 12
        let startY = h * 0.14
        let endY = h * 0.72
        let step = (endY - startY) / CGFloat(barbCount - 1)

        for i in 0..<barbCount {
            let y = startY + CGFloat(i) * step
            let progress = CGFloat(i) / CGFloat(barbCount - 1)

            // Barb angle: ~25° near tip, ~44° near base
            let angle = 25.0 + Double(progress) * 19.0
            let rad = angle * .pi / 180.0

            // Rachis x at this y (following the S-curve)
            let rX = rachisX + w * 0.012 * sin((1.0 - progress) * .pi)

            // Outer barb (shorter, narrower vane side)
            let outerExtent = w * (0.15 + progress * 0.06)
            let outerEndX = rX - cos(rad) * outerExtent
            let outerEndY = y - sin(rad) * outerExtent * 0.55
            path.move(to: CGPoint(x: rX, y: y))
            path.addLine(to: CGPoint(x: outerEndX, y: outerEndY))

            // Inner barb (longer, wider vane side)
            let innerExtent = w * (0.26 + progress * 0.08)
            let innerEndX = rX + cos(rad) * innerExtent
            let innerEndY = y - sin(rad) * innerExtent * 0.55
            path.move(to: CGPoint(x: rX, y: y))
            path.addLine(to: CGPoint(x: innerEndX, y: innerEndY))
        }

        // Downy/wispy barbs near calamus (looser, curving outward)
        let downCount = 4
        let downStart = h * 0.74
        let downEnd = h * 0.80
        let downStep = (downEnd - downStart) / CGFloat(downCount - 1)

        for i in 0..<downCount {
            let y = downStart + CGFloat(i) * downStep
            let rX = rachisX

            // Outer downy wisps — curve outward loosely
            let len = w * CGFloat(0.06 + 0.03 * Double(i))
            path.move(to: CGPoint(x: rX, y: y))
            path.addQuadCurve(
                to: CGPoint(x: rX - len, y: y - len * 0.3),
                control: CGPoint(x: rX - len * 0.6, y: y + len * 0.2)
            )

            // Inner downy wisps
            let iLen = w * CGFloat(0.08 + 0.04 * Double(i))
            path.move(to: CGPoint(x: rX, y: y))
            path.addQuadCurve(
                to: CGPoint(x: rX + iLen, y: y - iLen * 0.25),
                control: CGPoint(x: rX + iLen * 0.5, y: y + iLen * 0.15)
            )
        }

        return path
    }
}

/// The pale, translucent calamus (quill base) — bottom ~20% of the feather.
struct FeatherCalamus: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let rachisX: CGFloat = w * 0.38
        let calamousHalfW: CGFloat = w * 0.016

        var path = Path()
        // Narrow tube from vane start down to bottom
        path.move(to: CGPoint(x: rachisX - w * 0.03, y: h * 0.80))
        path.addCurve(
            to: CGPoint(x: rachisX, y: h),
            control1: CGPoint(x: rachisX - calamousHalfW * 1.8, y: h * 0.87),
            control2: CGPoint(x: rachisX - calamousHalfW, y: h * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: rachisX + w * 0.05, y: h * 0.80),
            control1: CGPoint(x: rachisX + calamousHalfW, y: h * 0.95),
            control2: CGPoint(x: rachisX + calamousHalfW * 1.8, y: h * 0.87)
        )
        path.closeSubpath()
        return path
    }
}

struct PoolWaterHitShape: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width,
                    y: rect.minY + y * rect.height)
        }

        let pts: [CGPoint] = [
            p(0.53, 0.65),
            p(1.1, 0.73),
            p(1.0, 1.01),
            p(0.67, 0.92),
            p(0.21, 0.8)
        ]

        var path = Path()
        path.addLines(pts)
        path.closeSubpath()
        return path
    }
}

#Preview {
    GardenView(showMainApp: .constant(true))
        .environmentObject(RevealedPoemsStore())
}
