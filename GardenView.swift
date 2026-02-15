//
//  GardenView.swift - POOL BOUNDARIES FIXED
//  WhispersoftheGardenApp
//
//  Lily pads only appear IN THE POOL where they should be!
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

struct DustParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var drift: CGFloat
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

struct RosePetal: Identifiable {
    let id = UUID()
    var position: CGPoint
    var rotation: CGFloat
    var rotationSpeed: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var drift: CGFloat
    var color: Color
}

enum MovementStyle: CaseIterable {
    case gentle, wavy, circular, zigzag, stillness
}

struct GardenView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    
    @State private var showPoem = false
    @State private var currentPoem: Poem?
    @State private var pads: [Pad] = []
    @State private var time: TimeInterval = 0
    @State private var dustParticles: [DustParticle] = []
    @State private var fireflies: [Firefly] = []
    @State private var waterRipples: [WaterRipple] = []
    @State private var rosePetals: [RosePetal] = []
    @State private var breathingIntensity: CGFloat = 0
    
    let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

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

                // ✅ POOL SHAPE - Only taps in pool register
                PoolWaterHitShape()
                    .fill(.clear)
                    .contentShape(PoolWaterHitShape())
                    .onTapGesture { location in
                        handleTap(at: location, in: geo.size)
                    }
                
                ForEach(waterRipples) { ripple in
                    Circle()
                        .stroke(Color.cyan.opacity(ripple.opacity), lineWidth: 1.2)
                        .frame(width: ripple.radius * 2, height: ripple.radius * 2)
                        .position(ripple.center)
                }

                ForEach(pads) { pad in
                    renderPad(pad, in: geo.size)
                }
                
                ForEach(rosePetals) { petal in
                    Ellipse()
                        .fill(petal.color.opacity(petal.opacity))
                        .frame(width: petal.size * 1.5, height: petal.size)
                        .rotationEffect(.degrees(petal.rotation))
                        .blur(radius: 0.5)
                        .position(petal.position)
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
                        .blur(radius: firefly.size * 0.3)
                        .position(firefly.position)
                }

                if let poem = currentPoem {
                    Color.black.opacity(showPoem ? 0.4 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.4)) {
                                showPoem = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                currentPoem = nil
                            }
                        }
                        .allowsHitTesting(showPoem)

                    PoemOverlayView(
                        persian: poem.persian,
                        english: poem.english,
                        culturalNote: poem.culturalNote,
                        reflection: poem.reflection
                    )
                    .opacity(showPoem ? 1 : 0)
                    .scaleEffect(showPoem ? 1 : 0.95)
                }
                
                ForEach(dustParticles) { particle in
                    Circle()
                        .fill(Color.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size * 0.15)
                        .shadow(color: .white.opacity(particle.opacity * 0.5), radius: particle.size * 0.5)
                        .position(particle.position)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            initializeDustParticles(screenSize: UIScreen.main.bounds.size)
            for _ in 0..<3 {
                spawnRosePetal(screenSize: UIScreen.main.bounds.size, randomY: true)
            }
            for _ in 0..<6 {
                spawnFirefly(screenSize: UIScreen.main.bounds.size, randomY: true)
            }
        }
        .onReceive(timer) { _ in
            time += 0.08
            breathingIntensity = sin(time * 0.3) * 0.5 + 0.5
            updatePads()
            updateDustParticles(screenSize: UIScreen.main.bounds.size)
            updateFireflies(screenSize: UIScreen.main.bounds.size)
            updateWaterRipples()
            updateRosePetals(screenSize: UIScreen.main.bounds.size)
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
        .animation(.easeInOut(duration: 2.5), value: pad.anchor)
        .animation(.easeInOut(duration: 0.5), value: pad.isLotus)
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        addNewPad()
        createWaterRipple(at: location)
        
        for _ in 0..<2 {
            spawnRosePetal(screenSize: size)
        }
        
        bobNearbyPads(tapLocation: CGPoint(
            x: location.x / size.width,
            y: location.y / size.height
        ))
    }
    
    private func updatePads() {
        for index in pads.indices {
            if abs(pads[index].bobOffset) > 0.01 || abs(pads[index].bobVelocity) > 0.01 {
                pads[index].bobVelocity += -pads[index].bobOffset * 0.3
                pads[index].bobVelocity *= 0.85
                pads[index].bobOffset += pads[index].bobVelocity
            } else {
                pads[index].bobOffset = 0
                pads[index].bobVelocity = 0
            }
            
            if pads[index].glowIntensity > 0 {
                pads[index].glowIntensity = max(0, pads[index].glowIntensity - 0.015)
            }
            
            let movement = calculateMovement(for: pads[index], time: time)
            var newPosition = CGPoint(
                x: pads[index].anchor.x + movement.x,
                y: pads[index].anchor.y + movement.y
            )
            
            if pads.count > 1 {
                let minDistance: CGFloat = 0.16
                for otherIndex in pads.indices where otherIndex != index {
                    let dist = distance(newPosition, pads[otherIndex].anchor)
                    if dist < minDistance && dist > 0.001 {
                        let pushStrength = (minDistance - dist) * 0.03
                        let dx = (newPosition.x - pads[otherIndex].anchor.x) / dist
                        let dy = (newPosition.y - pads[otherIndex].anchor.y) / dist
                        newPosition.x += dx * pushStrength
                        newPosition.y += dy * pushStrength
                    }
                }
            }
            
            // ✅ Keep pads in pool
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
            withAnimation(.easeOut(duration: 0.3)) {
                pads.removeFirst()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                createLilyPad()
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
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            pads.append(newPad)
        }
    }
    
    private func transformToLotus() {
        guard let lastIndex = pads.indices.last else { return }
        
        pads[lastIndex].isLotus = true
        pads[lastIndex].glowIntensity = 1.0
        
        if let poem = pads[lastIndex].storedPoem {
            currentPoem = poem
            revealedPoemsStore.revealPoem(poem)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                showPoem = true
            }
            
            for _ in 0..<4 {
                spawnRosePetal(screenSize: UIScreen.main.bounds.size)
            }
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
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // ✅ POOL BOUNDARIES - Lily pads only spawn here
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
    
    private func initializeDustParticles(screenSize: CGSize) {
        dustParticles.removeAll()
        for _ in 0..<50 {
            dustParticles.append(createDustParticle(screenSize: screenSize, randomY: true))
        }
    }
    
    private func createDustParticle(screenSize: CGSize, randomY: Bool = false) -> DustParticle {
        return DustParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...screenSize.width),
                y: randomY ? CGFloat.random(in: 0...screenSize.height) : CGFloat.random(in: -50...0)
            ),
            size: CGFloat.random(in: 3...7),
            opacity: Double.random(in: 0.5...0.8),
            speed: CGFloat.random(in: 0.2...0.6),
            drift: CGFloat.random(in: -0.8...0.8)
        )
    }
    
    private func updateDustParticles(screenSize: CGSize) {
        for index in dustParticles.indices {
            dustParticles[index].position.y += dustParticles[index].speed
            let sway = sin(time * 0.5 + CGFloat(index) * 0.3) * 0.8
            dustParticles[index].position.x += dustParticles[index].drift + sway
            
            if dustParticles[index].position.y > screenSize.height + 50 {
                dustParticles[index] = createDustParticle(screenSize: screenSize)
            }
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
    
    private func spawnRosePetal(screenSize: CGSize, randomY: Bool = false) {
        let colors: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.4),
            Color(red: 1.0, green: 0.4, blue: 0.5),
            Color(red: 0.8, green: 0.2, blue: 0.3)
        ]
        
        let petal = RosePetal(
            position: CGPoint(
                x: CGFloat.random(in: 0...screenSize.width),
                y: randomY ? CGFloat.random(in: 0...screenSize.height) : CGFloat.random(in: -50...0)
            ),
            rotation: CGFloat.random(in: 0...360),
            rotationSpeed: CGFloat.random(in: 0.5...2),
            size: CGFloat.random(in: 8...15),
            opacity: Double.random(in: 0.6...0.9),
            speed: CGFloat.random(in: 0.3...0.7),
            drift: CGFloat.random(in: -0.5...0.5),
            color: colors.randomElement()!
        )
        rosePetals.append(petal)
        
        if rosePetals.count > 8 {
            rosePetals.removeFirst()
        }
    }
    
    private func updateRosePetals(screenSize: CGSize) {
        for index in rosePetals.indices {
            rosePetals[index].position.y += rosePetals[index].speed
            let sway = sin(time * 0.4 + CGFloat(index) * 0.5) * 1.2
            rosePetals[index].position.x += rosePetals[index].drift + sway
            rosePetals[index].rotation += rosePetals[index].rotationSpeed
            
            if rosePetals[index].position.y > screenSize.height + 50 {
                rosePetals[index] = createRosePetal(screenSize: screenSize)
            }
        }
    }
    
    private func createRosePetal(screenSize: CGSize) -> RosePetal {
        let colors: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.4),
            Color(red: 1.0, green: 0.4, blue: 0.5),
            Color(red: 0.8, green: 0.2, blue: 0.3)
        ]
        
        return RosePetal(
            position: CGPoint(x: CGFloat.random(in: 0...screenSize.width), y: -20),
            rotation: CGFloat.random(in: 0...360),
            rotationSpeed: CGFloat.random(in: 0.5...2),
            size: CGFloat.random(in: 8...15),
            opacity: Double.random(in: 0.6...0.9),
            speed: CGFloat.random(in: 0.3...0.7),
            drift: CGFloat.random(in: -0.5...0.5),
            color: colors.randomElement()!
        )
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
    
    private func updateFireflies(screenSize: CGSize) {
        for index in fireflies.indices {
            fireflies[index].position.y -= fireflies[index].speed
            let sway = sin(time * 0.3 + CGFloat(index) * 0.4) * 0.6
            fireflies[index].position.x += fireflies[index].drift + sway
            
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

// ✅ POOL SHAPE - Defines the tap area
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
    GardenView()
        .environmentObject(RevealedPoemsStore())
}
