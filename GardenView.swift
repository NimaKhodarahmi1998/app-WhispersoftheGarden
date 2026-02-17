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
    @Binding var showMainApp: Bool  // ✅ ADDED: For back button
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

                GardenParticleCanvas(petalBurst: petalBurst, reduceMotion: reduceMotion)

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
                        .blur(radius: firefly.size * 0.3)
                        .position(firefly.position)
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
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showPoem = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    currentPoem = nil
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
                                    nightingaleFlyBackIn()
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showNightingaleCouplet = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    currentNightingaleCouplet = nil
                                    nightingaleFlyBackIn()
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
                        reflection: couplet.reflection
                    )
                    .opacity(showNightingaleCouplet ? 1 : 0)
                    .scaleEffect(showNightingaleCouplet ? 1 : 0.95)
                    .allowsHitTesting(false)
                }

            }
        }
        .ignoresSafeArea()
        .onAppear {
            for _ in 0..<6 {
                spawnFirefly(screenSize: UIScreen.main.bounds.size, randomY: true)
            }
            checkNightingaleAppearance()
        }
        .onReceive(timer) { now in
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

            checkNightingaleAppearance()
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
        .position(x: x, y: y)
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut(duration: 0.5), value: pad.isLotus)
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        addNewPad()
        createWaterRipple(at: location)
        petalBurst += 1

        bobNearbyPads(tapLocation: CGPoint(
            x: location.x / size.width,
            y: location.y / size.height
        ))
    }

    private func updatePads(dt: TimeInterval) {
        let s = CGFloat(dt / 0.08) // scale factor: 1.0 at the old 12.5fps rate

        for index in pads.indices {
            // Spring-damper bob (scaled for frame rate)
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

            let movement = calculateMovement(for: pads[index], time: time)
            var newPosition = CGPoint(
                x: pads[index].anchor.x + movement.x * s,
                y: pads[index].anchor.y + movement.y * s
            )

            if pads.count > 1 {
                let minDistance: CGFloat = 0.16
                for otherIndex in pads.indices where otherIndex != index {
                    let dist = distance(newPosition, pads[otherIndex].anchor)
                    if dist < minDistance && dist > 0.001 {
                        let pushStrength = (minDistance - dist) * 0.03 * s
                        let dx = (newPosition.x - pads[otherIndex].anchor.x) / dist
                        let dy = (newPosition.y - pads[otherIndex].anchor.y) / dist
                        newPosition.x += dx * pushStrength
                        newPosition.y += dy * pushStrength
                    }
                }
            }

            if isPointInPool(newPosition) {
                pads[index].anchor = newPosition
            }

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

    private func addNewPad() {
        let hasFullPool = pads.count == 5 && pads.allSatisfy { $0.isLotus }

        if hasFullPool {
            if reduceMotion {
                pads.removeFirst()
                createLilyPad()
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    pads.removeFirst()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    createLilyPad()
                }
            }
        } else if pads.isEmpty || pads.last?.isLotus == true {
            if pads.count < 5 {
                createLilyPad()
            }
        } else {
            transformToLotus()
        }
    }

    private func createLilyPad() {
        guard let poem = revealedPoemsStore.getNextPoem() else { return }

        let position = randomPointInPool()
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                pads.append(newPad)
            }
        }
    }

    private func transformToLotus() {
        guard let lastIndex = pads.indices.last else { return }

        pads[lastIndex].isLotus = true
        pads[lastIndex].glowIntensity = 1.0

        if let poem = pads[lastIndex].storedPoem {
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

    private func checkNightingaleAppearance() {
        guard !showNightingale, revealedPoemsStore.revealedCount >= 3 else { return }
        showNightingale = true
        nightingalePosition = nightingalePerchPositions[nightingalePerchIndex]
        if reduceMotion {
            nightingaleAppearOpacity = 1
        } else {
            withAnimation(.easeIn(duration: 1.5)) {
                nightingaleAppearOpacity = 1
            }
        }
    }

    private func handleNightingaleTap(in size: CGSize) {
        guard nightingaleIsPerched,
              !showPoem,
              !showNightingaleCouplet else { return }

        nightingaleIsPerched = false

        // Fly off-screen to the opposite side
        let flyOutRight = nightingalePosition.x < 0.5
        let flyOutX: CGFloat = flyOutRight ? 1.15 : -0.15
        let flyOutY: CGFloat = nightingalePosition.y - 0.12
        nightingaleFacingRight = flyOutRight

        if reduceMotion {
            nightingaleAppearOpacity = 0
            showBonusCouplet()
        } else {
            petalBurst += 1  // takeoff burst

            withAnimation(.easeIn(duration: 0.5)) {
                nightingalePosition = CGPoint(x: flyOutX, y: flyOutY)
                nightingaleAppearOpacity = 0
            }

            // Show couplet after the bird exits
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                showBonusCouplet()
            }
        }
    }

    private func nightingaleFlyBackIn() {
        // Advance to next perch
        nightingalePerchIndex = (nightingalePerchIndex + 1) % nightingalePerchPositions.count
        let destination = nightingalePerchPositions[nightingalePerchIndex]

        // Enter from the opposite side of the destination
        let enterFromRight = destination.x < 0.5
        let enterX: CGFloat = enterFromRight ? 1.15 : -0.15
        let enterY: CGFloat = destination.y - 0.12
        // Face toward the destination (opposite of entry side)
        nightingaleFacingRight = !enterFromRight

        if reduceMotion {
            nightingalePosition = destination
            nightingaleIsPerched = true
            nightingaleAppearOpacity = 1
        } else {
            // Snap to off-screen entry point (no animation)
            nightingalePosition = CGPoint(x: enterX, y: enterY)

            // Glide in to the new perch
            withAnimation(.easeOut(duration: 0.6)) {
                nightingalePosition = destination
                nightingaleAppearOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                nightingaleIsPerched = true
                petalBurst += 1  // landing burst
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
        let baseSpeed: CGFloat = 0.0006 * pad.speed

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
