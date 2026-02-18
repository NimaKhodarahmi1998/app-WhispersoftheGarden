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

struct WaterRipple: Identifiable {
    let id = UUID()
    var center: CGPoint
    var radius: CGFloat
    var opacity: Double
    var createdAt: Date
}

enum MovementStyle: CaseIterable {
    case gentle, wavy, circular, zigzag, stillness
}

struct GardenView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @Binding var showMainApp: Bool
    var isActive: Bool = true  // pause updates when off-screen (e.g. Library tab)
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var showPoem = false
    @State private var currentPoem: Poem?
    @State private var pads: [Pad] = []
    @State private var time: TimeInterval = 0
    @State private var fireflies: [Firefly] = []
    @State private var waterRipples: [WaterRipple] = []
    @State private var petalBurst = 0
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

                PoolWaterHitShape()
                    .fill(.clear)
                    .contentShape(PoolWaterHitShape())
                    .onTapGesture { location in
                        handleTap(at: location, in: geo.size)
                    }
                    .accessibilityLabel("Garden pool")
                    .accessibilityHint("Double tap to create a lily pad")
                    .accessibilityAddTraits(.isButton)

                ForEach(waterRipples) { ripple in
                    Circle()
                        .stroke(Color.cyan.opacity(ripple.opacity), lineWidth: 1.2)
                        .frame(width: ripple.radius * 2, height: ripple.radius * 2)
                        .position(ripple.center)
                }

                ForEach(pads) { pad in
                    renderPad(pad, in: geo.size)
                }

                // Nightingale — between pads and particle canvas
                if showNightingale {
                    NightingaleView(
                        size: geo.size.width * 0.10,
                        isPerched: nightingaleIsPerched
                    )
                    .scaleEffect(x: nightingaleFacingRight ? 1 : -1, y: 1)
                    .position(
                        x: nightingalePosition.x * geo.size.width,
                        y: nightingalePosition.y * geo.size.height
                    )
                    .opacity(nightingaleAppearOpacity)
                    .onTapGesture {
                        handleNightingaleTap(in: geo.size)
                    }
                }

                if isActive {
                    GardenParticleCanvas(petalBurst: petalBurst, reduceMotion: reduceMotion)
                }

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

                // Garden hints — tutorial
                if let stage = hintStore.activeHint, hintVisible,
                   !(stage == .tapNightingale && !showNightingale) {
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

                // Garden hints — persistent invitation glow (post-tutorial)
                if let invitation = invitationStage(in: geo.size), hintVisible {
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
                            if reduceMotion {
                                withAnimation(.default) {
                                    showPoem = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentPoem = nil
                                    checkNightingaleApproachHint()
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showPoem = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    currentPoem = nil
                                    checkNightingaleApproachHint()
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
                    .font(.system(size: 16, weight: .light, design: .serif))
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
                }

            }
        }
        .ignoresSafeArea()
        .onAppear {
            for _ in 0..<6 {
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
                updateWaterRipples()
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
        let normalized = CGPoint(x: location.x / size.width,
                                 y: location.y / size.height)
        let safePoint = pushInsidePool(normalized, margin: 0.07)

        // Remove oldest pad BEFORE finding spot, so we don't avoid a pad that's leaving
        if pads.count >= 5 {
            if reduceMotion {
                pads.removeFirst()
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    pads.removeFirst()
                }
            }
        }

        let separated = findNonOverlappingSpot(near: safePoint, screenSize: size)
        createLilyPad(at: separated)
        createWaterRipple(at: location)
        petalBurst += 1
        bobNearbyPads(tapLocation: normalized)
        hintStore.markPoolTapped()
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
        guard !pad.isLotus,
              let index = pads.firstIndex(where: { $0.id == pad.id }) else { return }

        pads[index].isLotus = true
        pads[index].glowIntensity = 1.0

        if let poem = pads[index].storedPoem {
            currentPoem = poem
            revealedPoemsStore.revealPoem(poem)

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

        poolPoemsSinceNightingale += 1
        if poolPoemsSinceNightingale >= 3 && !showNightingale {
            nightingaleFlyIn()
        }
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
        // Advance to next perch
        nightingalePerchIndex = (nightingalePerchIndex + 1) % nightingalePerchPositions.count
        let destination = nightingalePerchPositions[nightingalePerchIndex]

        // Enter from the opposite side of the destination
        let enterFromRight = destination.x < 0.5
        let enterX: CGFloat = enterFromRight ? 1.15 : -0.15
        let enterY: CGFloat = destination.y - 0.15
        nightingaleFacingRight = !enterFromRight

        showNightingale = true
        nightingaleIsPerched = false

        if reduceMotion {
            nightingalePosition = destination
            nightingaleIsPerched = true
            nightingaleAppearOpacity = 1
        } else {
            // Snap to off-screen entry point (invisible)
            nightingalePosition = CGPoint(x: enterX, y: enterY)
            nightingaleAppearOpacity = 0

            let midX = (enterX + destination.x) / 2

            // Phase 1: Glide in from off-screen, rising to arc peak
            withAnimation(.easeOut(duration: 0.5)) {
                nightingalePosition = CGPoint(x: midX, y: destination.y - 0.26)
                nightingaleAppearOpacity = 1
            }

            // Phase 2: Descend toward the perch area
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    nightingalePosition = CGPoint(
                        x: destination.x + (enterFromRight ? 0.04 : -0.04),
                        y: destination.y - 0.06
                    )
                }
            }

            // Phase 3: Settle onto perch with a gentle spring bob
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    nightingalePosition = destination
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                nightingaleIsPerched = true
                petalBurst += 1  // landing burst
            }
        }
    }

    private func handleNightingaleTap(in size: CGSize) {
        guard nightingaleIsPerched,
              !showPoem,
              !showNightingaleCouplet else { return }

        hintStore.markNightingaleTapped()
        nightingaleIsPerched = false

        let startPos = nightingalePosition
        let flyOutRight = startPos.x < 0.5
        let exitX: CGFloat = flyOutRight ? 1.15 : -0.15
        nightingaleFacingRight = flyOutRight

        if reduceMotion {
            nightingaleAppearOpacity = 0
            showBonusCouplet()
        } else {
            petalBurst += 1  // takeoff burst

            let dir: CGFloat = flyOutRight ? 1 : -1

            // Phase 1: Lift off — rise upward with slight lateral drift
            withAnimation(.easeOut(duration: 0.45)) {
                nightingalePosition = CGPoint(
                    x: startPos.x + dir * 0.10,
                    y: startPos.y - 0.22
                )
            }

            // Phase 2: Cruise — glide across at peak height
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    nightingalePosition = CGPoint(
                        x: startPos.x + dir * 0.45,
                        y: startPos.y - 0.28
                    )
                }
            }

            // Phase 3: Sweep out — descend slightly and exit, fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.5)) {
                    nightingalePosition = CGPoint(x: exitX, y: startPos.y - 0.15)
                    nightingaleAppearOpacity = 0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
                showBonusCouplet()
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
        showApproachFeather = true
        featherFallProgress = 0
        featherOpacity = 0

        // Feather fades in and drifts down
        withAnimation(.easeIn(duration: 0.3)) {
            featherOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 2.8)) {
            featherFallProgress = 1.0
        }

        // Whisper text appears as feather reaches mid-screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.6)) {
                showApproachWhisper = true
            }
        }

        // Feather fades out near the end
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                featherOpacity = 0
            }
        }

        // Whisper fades out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showApproachWhisper = false
            }
        }

        // Reset feather state
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            showApproachFeather = false
            featherFallProgress = 0
        }
    }

    @ViewBuilder
    private func nightingaleApproachHintView(in size: CGSize) -> some View {
        let startY: CGFloat = -30
        let endY: CGFloat = size.height * 0.45
        let currentY = startY + (endY - startY) * featherFallProgress

        // Gentle S-curve sway as it falls
        let swayX = sin(featherFallProgress * .pi * 2.5) * 22
        let baseX = size.width * 0.48

        // Rotation: tilts as it drifts
        let rotation = -25.0 + Double(featherFallProgress) * 55.0

        ZStack {
            // Dim overlay — darkens the garden so the light stands out
            if showApproachFeather {
                Color.black
                    .opacity(0.3 * featherOpacity)
                    .ignoresSafeArea()
            }

            // Holy light — golden cone raying down from above
            if showApproachFeather {
                let apexX = size.width * 0.48
                let beamLeft = size.width * 0.15
                let beamRight = size.width * 0.82
                let beamBottom = size.height * 0.62

                // Light cone shape
                Path { path in
                    path.move(to: CGPoint(x: apexX, y: -10))
                    path.addLine(to: CGPoint(x: beamLeft, y: beamBottom))
                    path.addLine(to: CGPoint(x: beamRight, y: beamBottom))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.7).opacity(0.22),
                            Color(red: 1.0, green: 0.92, blue: 0.6).opacity(0.10),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 18)
                .opacity(featherOpacity)
                .ignoresSafeArea()

                // Bright source glow at apex
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.96, blue: 0.8).opacity(0.35),
                        Color(red: 1.0, green: 0.92, blue: 0.6).opacity(0.12),
                        Color.clear
                    ],
                    center: UnitPoint(x: apexX / size.width, y: 0),
                    startRadius: 0,
                    endRadius: size.height * 0.18
                )
                .opacity(featherOpacity)
                .ignoresSafeArea()
            }

            // Drifting golden feather
            if showApproachFeather {
                ZStack {
                    // Soft glow around feather
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.92, blue: 0.55).opacity(0.35),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)

                    // Feather shape — asymmetric golden leaf
                    FeatherShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.93, blue: 0.58),
                                    Color(red: 0.92, green: 0.78, blue: 0.38)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12, height: 34)
                }
                .rotationEffect(.degrees(rotation))
                .position(x: baseX + swayX, y: currentY)
                .opacity(featherOpacity)
            }

            // Whisper text
            if showApproachWhisper {
                Text(currentApproachWhisper)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(Color(red: 1.0, green: 0.92, blue: 0.65))
                    .shadow(color: .black.opacity(0.8), radius: 8)
                    .position(x: size.width * 0.5, y: size.height * 0.52)
                    .transition(.opacity)
            }
        }
    }

    private func nightingaleDismiss() {
        showNightingale = false
        nightingaleAppearOpacity = 0
        nightingaleIsPerched = true
        poolPoemsSinceNightingale = 0

        // Departure whisper — cycles through different lines
        currentDepartureWhisper = departureWhispers[
            (nightingaleCoupletIndex - 1) % departureWhispers.count
        ]
        withAnimation(.easeIn(duration: 0.8)) {
            nightingaleWhisperOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 1.2)) {
                nightingaleWhisperOpacity = 0
            }
        }
    }


    private func showBonusCouplet() {
        let couplet = NightingaleCouplets.couplets[nightingaleCoupletIndex % NightingaleCouplets.couplets.count]
        nightingaleCoupletIndex += 1
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
        case .tapPool:
            return CGPoint(x: 0.70 * size.width, y: 0.82 * size.height)
        case .tapLilyPad:
            if let firstPad = pads.first(where: { !$0.isLotus }) {
                return CGPoint(x: firstPad.anchor.x * size.width,
                               y: firstPad.anchor.y * size.height)
            }
            return CGPoint(x: 0.70 * size.width, y: 0.82 * size.height)
        case .tapNightingale:
            return CGPoint(x: nightingalePosition.x * size.width,
                           y: nightingalePosition.y * size.height)
        }
    }

    private func invitationStage(in size: CGSize) -> (stage: GardenHintStage, position: CGPoint)? {
        guard hintStore.isTutorialComplete else { return nil }
        guard !showPoem, !showNightingaleCouplet else { return nil }

        if showNightingale && nightingaleIsPerched {
            return (.tapNightingale, hintPosition(for: .tapNightingale, in: size))
        }
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

    private func createWaterRipple(at position: CGPoint) {
        for i in 0..<2 {
            let ripple = WaterRipple(
                center: position,
                radius: 15,
                opacity: 0.4 - Double(i) * 0.1,
                createdAt: Date().addingTimeInterval(Double(i) * 0.08)
            )
            waterRipples.append(ripple)
        }
    }

    private func updateWaterRipples() {
        let now = Date()
        waterRipples = waterRipples.filter { now.timeIntervalSince($0.createdAt) < 1.2 }

        for index in waterRipples.indices {
            let age = now.timeIntervalSince(waterRipples[index].createdAt)
            waterRipples[index].radius = 15 + CGFloat(age) * 40
            waterRipples[index].opacity = max(0, waterRipples[index].opacity - age * 0.35)
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
}

struct FeatherShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Asymmetric feather: tip at top, wider right vane, narrower left
        path.move(to: CGPoint(x: w * 0.42, y: 0))

        // Right vane — fuller curve
        path.addQuadCurve(
            to: CGPoint(x: w * 0.46, y: h),
            control: CGPoint(x: w * 1.05, y: h * 0.32)
        )

        // Left vane — tighter curve
        path.addQuadCurve(
            to: CGPoint(x: w * 0.42, y: 0),
            control: CGPoint(x: -w * 0.05, y: h * 0.45)
        )

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
