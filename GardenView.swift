//
//  GardenView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//


import SwiftUI

struct Pad: Identifiable, Equatable {
    let id = UUID()
    var anchor: CGPoint   // normalized (0...1)
    var isLotus: Bool     // false = lilypad, true = LotusFull
    var targetAnchor: CGPoint  // where it's drifting to
    var movementStyle: MovementStyle
    var phase: CGFloat  // random offset for wave patterns
    var speed: CGFloat  // individual movement speed
    var bobOffset: CGFloat = 0  // vertical bob offset for tap response
    var bobVelocity: CGFloat = 0  // bob animation velocity
    var glowIntensity: CGFloat = 0  // glow when transforming to lotus
}

struct DustParticle: Identifiable {
    let id = UUID()
    var position: CGPoint  // screen coordinates
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var drift: CGFloat  // horizontal drift amount
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
    var center: CGPoint  // where tap occurred
    var radius: CGFloat  // current radius
    var opacity: Double  // fades out as it expands
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
    var color: Color  // pink or red shades
}

enum MovementStyle: CaseIterable {
    case gentle      // slow subtle drift
    case wavy        // sine wave pattern
    case circular    // small circular motion
    case zigzag      // figure-8 pattern
    case stillness   // barely moves
}

import SwiftUI

struct GardenView: View {
    @State private var showPoem = false
    @State private var currentPoem: Poem?

    @State private var pads: [Pad] = []
    @State private var time: TimeInterval = 0  // for wave calculations
    @State private var cycleIndex: Int = 0  // which pad to cycle next when we have 5
    @State private var dustParticles: [DustParticle] = []  // floating dust particles
    @State private var fireflies: [Firefly] = []  // magical fireflies
    @State private var waterRipples: [WaterRipple] = []  // water ripples from taps
    @State private var rosePetals: [RosePetal] = []  // falling rose petals
    @State private var breathingIntensity: CGFloat = 0  // breathing light effect
    
    // Single timer for organic movements
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Add a background color first
                Color.black
                    .ignoresSafeArea()
                
                Image("GardenView")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                // Warm color overlay (subtle peachy/golden tint)
                Color(red: 1.0, green: 0.95, blue: 0.85)
                    .opacity(0.08 + breathingIntensity * 0.02)  // breathing effect
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Vignette (darker edges for cozy feel)
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: geo.size.width * 0.3,
                    endRadius: geo.size.width * 0.7
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Tap zone (your pool water shape)
                PoolWaterHitShape()
                    .fill(.clear)
                    .contentShape(PoolWaterHitShape())
                    .onTapGesture { location in
                        // 1) show poem
                        currentPoem = PoemLibrary.poems.randomElement()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showPoem = (currentPoem != nil)
                        }

                        // 2) add a new pad
                        addNewPad()
                        
                        // 3) create water ripple at tap location
                        createWaterRipple(at: CGPoint(x: location.x, y: location.y))
                        
                        // 4) spawn rose petal burst when poem appears
                        if currentPoem != nil {
                            for _ in 0..<4 {  // burst of 4 petals
                                spawnRosePetal(screenSize: geo.size)
                            }
                        }
                        
                        // 5) make nearby lily pads bob
                        bobNearbyPads(tapLocation: CGPoint(
                            x: location.x / geo.size.width,
                            y: location.y / geo.size.height
                        ))
                    }

                // Optional: debug the pool hit shape
                // PoolWaterHitShape()
                //     .stroke(.white.opacity(0.8), lineWidth: 2)
                
                // Water ripples (on pool surface)
                ForEach(waterRipples) { ripple in
                    Circle()
                        .stroke(
                            Color.cyan.opacity(ripple.opacity),  // cyan is more visible
                            lineWidth: 1.2
                        )
                        .frame(width: ripple.radius * 2, height: ripple.radius * 2)
                        .position(ripple.center)
                }

                // Render pads (on top of the water)
                ForEach(pads) { pad in
                    let size = geo.size.width * 0.12
                    let half = size / 2

                    let rawX = pad.anchor.x * geo.size.width
                    let rawY = pad.anchor.y * geo.size.height + pad.bobOffset

                    let x = min(max(rawX, half), geo.size.width - half)
                    let y = min(max(rawY, half), geo.size.height - half)

                    ZStack {
                        // Lotus glow effect (when transforming)
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
                                        endRadius: size * 0.8
                                    )
                                )
                                .frame(width: size * 1.6, height: size * 1.6)
                        }
                        
                        Image(pad.isLotus ? "LotusFull" : "LilyPad")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                    }
                    .position(x: x, y: y)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 2.5), value: pad.anchor)
                    .animation(.easeInOut(duration: 0.5), value: pad.isLotus)
                }
                
                // Rose petals (falling through the air)
                ForEach(rosePetals) { petal in
                    Ellipse()
                        .fill(petal.color.opacity(petal.opacity))
                        .frame(width: petal.size * 1.5, height: petal.size)
                        .rotationEffect(.degrees(petal.rotation))
                        .blur(radius: 0.5)
                        .position(petal.position)
                }
                
                // Fireflies (magical floating lights)
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

                // Poem overlay - keep in hierarchy for animation
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
                        .allowsHitTesting(showPoem)  // only allow taps when visible

                    PoemOverlayView(
                        persian: poem.persian,
                        english: poem.english,
                        culturalNote: poem.culturalNote,
                        reflection: poem.reflection
                    )
                    .opacity(showPoem ? 1 : 0)
                    .scaleEffect(showPoem ? 1 : 0.95)
                }
                
                // Dust particles layer (on top of everything)
                ForEach(dustParticles) { particle in
                    Circle()
                        .fill(Color.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size * 0.15)  // reduced blur from 0.2 for sharper visibility
                        .shadow(color: .white.opacity(particle.opacity * 0.5), radius: particle.size * 0.5)  // add glow
                        .position(particle.position)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Initialize dust particles
            initializeDustParticles(screenSize: UIScreen.main.bounds.size)
            // Initialize more rose petals
            for _ in 0..<5 {
                spawnRosePetal(screenSize: UIScreen.main.bounds.size, randomY: true)
            }
            // Initialize fireflies
            for _ in 0..<10 {
                spawnFirefly(screenSize: UIScreen.main.bounds.size, randomY: true)
            }
        }
        .onReceive(timer) { _ in
            time += 0.05
            
            // Update breathing light effect (gentle pulsing)
            breathingIntensity = sin(time * 0.3) * 0.5 + 0.5  // oscillates 0...1
            
            for index in pads.indices {
                let pad = pads[index]
                
                // Update lily pad bob physics (spring damping)
                if abs(pads[index].bobOffset) > 0.01 || abs(pads[index].bobVelocity) > 0.01 {
                    pads[index].bobVelocity += -pads[index].bobOffset * 0.3  // spring force
                    pads[index].bobVelocity *= 0.85  // damping
                    pads[index].bobOffset += pads[index].bobVelocity
                } else {
                    pads[index].bobOffset = 0
                    pads[index].bobVelocity = 0
                }
                
                // Fade out lotus glow
                if pads[index].glowIntensity > 0 {
                    pads[index].glowIntensity = max(0, pads[index].glowIntensity - 0.015)
                }
                
                // Calculate desired movement based on style
                let movement = calculateMovement(for: pad, time: time)
                var newPosition = CGPoint(
                    x: pad.anchor.x + movement.x,
                    y: pad.anchor.y + movement.y
                )
                
                // Apply repulsion from ALL other pads
                let minDistance: CGFloat = 0.16
                var totalRepulsionX: CGFloat = 0
                var totalRepulsionY: CGFloat = 0
                
                for otherIndex in pads.indices where otherIndex != index {
                    let otherPad = pads[otherIndex]
                    let dist = distance(newPosition, otherPad.anchor)
                    
                    if dist < minDistance && dist > 0 {
                        // Calculate repulsion force (stronger when closer)
                        let repulsionStrength = (minDistance - dist) / minDistance
                        let dx = newPosition.x - otherPad.anchor.x
                        let dy = newPosition.y - otherPad.anchor.y
                        let angle = atan2(dy, dx)
                        
                        // Apply gentle repulsion
                        let pushForce = 0.005 * repulsionStrength
                        totalRepulsionX += cos(angle) * pushForce
                        totalRepulsionY += sin(angle) * pushForce
                    }
                }
                
                // Apply accumulated repulsion
                newPosition = CGPoint(
                    x: newPosition.x + totalRepulsionX,
                    y: newPosition.y + totalRepulsionY
                )
                
                // Always update position if valid (even tiny movements)
                if isPointInPool(newPosition) {
                    pads[index].anchor = newPosition
                }
                
                // Get new target more frequently to keep pads wandering
                let distToTarget = distance(pad.anchor, pad.targetAnchor)
                if distToTarget < 0.04 || Int(time * 20) % 200 == index * 40 {
                    pads[index].targetAnchor = randomPointInPool()
                    // Occasionally change movement style for variety
                    if Double.random(in: 0...1) < 0.15 {
                        pads[index].movementStyle = MovementStyle.allCases.randomElement()!
                        pads[index].phase = CGFloat.random(in: 0...(2 * .pi))
                    }
                }
            }
            
            // Update dust particles
            updateDustParticles(screenSize: UIScreen.main.bounds.size)
            
            // Update fireflies
            updateFireflies(screenSize: UIScreen.main.bounds.size)
            
            // Update water ripples
            updateWaterRipples()
            
            // Update rose petals
            updateRosePetals(screenSize: UIScreen.main.bounds.size)
        }
    }
    
    // Initialize dust particles
    private func initializeDustParticles(screenSize: CGSize) {
        dustParticles.removeAll()
        // Create initial particles spread across the screen
        for _ in 0..<80 {  // increased from 60 for more visible effect
            dustParticles.append(createDustParticle(screenSize: screenSize, randomY: true))
        }
    }
    
    // Create a single dust particle
    private func createDustParticle(screenSize: CGSize, randomY: Bool = false) -> DustParticle {
        return DustParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...screenSize.width),
                y: randomY ? CGFloat.random(in: 0...screenSize.height) : CGFloat.random(in: -50...0)
            ),
            size: CGFloat.random(in: 3...7),  // increased from 2...5 for much better visibility
            opacity: Double.random(in: 0.5...0.8),  // increased from 0.3...0.6 for much better visibility
            speed: CGFloat.random(in: 0.2...0.6),
            drift: CGFloat.random(in: -0.8...0.8)
        )
    }
    
    // Update dust particles (move down and recycle)
    private func updateDustParticles(screenSize: CGSize) {
        for index in dustParticles.indices {
            // Move particle down
            dustParticles[index].position.y += dustParticles[index].speed
            
            // Add gentle left-to-right swaying motion
            let sway = sin(time * 0.5 + CGFloat(index) * 0.3) * 0.8  // gentle wave motion
            dustParticles[index].position.x += dustParticles[index].drift + sway
            
            // Recycle particle when it goes off screen
            if dustParticles[index].position.y > screenSize.height + 50 {
                dustParticles[index] = createDustParticle(screenSize: screenSize)
            }
        }
    }
    
    // MARK: - Water Ripples
    
    private func createWaterRipple(at position: CGPoint) {
        // Create visible but subtle ripples
        for i in 0..<2 {
            let ripple = WaterRipple(
                center: position,
                radius: 15,
                opacity: 0.4 - Double(i) * 0.1,  // visible opacity
                createdAt: Date().addingTimeInterval(Double(i) * 0.08)
            )
            waterRipples.append(ripple)
        }
    }
    
    private func updateWaterRipples() {
        let now = Date()
        waterRipples = waterRipples.filter { ripple in
            now.timeIntervalSince(ripple.createdAt) < 1.2
        }
        
        for index in waterRipples.indices {
            let age = now.timeIntervalSince(waterRipples[index].createdAt)
            // Gentle expansion
            waterRipples[index].radius = 15 + CGFloat(age) * 40
            // Smooth fade
            waterRipples[index].opacity = max(0, waterRipples[index].opacity - age * 0.35)
        }
    }
    
    // MARK: - Rose Petals
    
    private func spawnRosePetal(screenSize: CGSize, randomY: Bool = false) {
        let colors: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.4),  // deep pink
            Color(red: 1.0, green: 0.4, blue: 0.5),  // light pink
            Color(red: 0.8, green: 0.2, blue: 0.3)   // dark rose
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
        
        // Keep max 12 petals (increased from 8)
        if rosePetals.count > 12 {
            rosePetals.removeFirst()
        }
    }
    
    private func updateRosePetals(screenSize: CGSize) {
        for index in rosePetals.indices {
            // Move petal down
            rosePetals[index].position.y += rosePetals[index].speed
            
            // Horizontal drift and sway
            let sway = sin(time * 0.4 + CGFloat(index) * 0.5) * 1.2
            rosePetals[index].position.x += rosePetals[index].drift + sway
            
            // Rotate as it falls
            rosePetals[index].rotation += rosePetals[index].rotationSpeed
            
            // Recycle when off screen
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
    
    // Calculate movement vector based on pad's style
    private func calculateMovement(for pad: Pad, time: TimeInterval) -> CGPoint {
        let baseSpeed: CGFloat = 0.0006 * pad.speed
        
        switch pad.movementStyle {
        case .gentle:
            // Continuous gentle drift with occasional direction changes
            let driftAngle = sin(time * 0.1 + pad.phase) * .pi
            let dx = cos(driftAngle) * baseSpeed * 2.5 + (pad.targetAnchor.x - pad.anchor.x) * baseSpeed * 1.5
            let dy = sin(driftAngle) * baseSpeed * 2.5 + (pad.targetAnchor.y - pad.anchor.y) * baseSpeed * 1.5
            return CGPoint(x: dx, y: dy)
            
        case .wavy:
            // Continuous sine wave motion with gentle drift
            let waveX = sin(time * pad.speed * 0.4 + pad.phase) * baseSpeed * 2.5
            let waveY = cos(time * pad.speed * 0.3 + pad.phase) * baseSpeed * 2.5
            let driftX = sin(time * 0.08 + pad.phase * 2) * baseSpeed * 1.5
            let driftY = cos(time * 0.06 + pad.phase * 3) * baseSpeed * 1.5
            return CGPoint(x: waveX + driftX, y: waveY + driftY)
            
        case .circular:
            // Continuous circular motion that slowly wanders
            let angle = time * pad.speed * 0.3 + pad.phase
            let wanderX = sin(time * 0.05 + pad.phase) * baseSpeed * 1
            let wanderY = cos(time * 0.04 + pad.phase * 2) * baseSpeed * 1
            return CGPoint(
                x: cos(angle) * baseSpeed * 2.5 + wanderX,
                y: sin(angle) * baseSpeed * 2.5 + wanderY
            )
            
        case .zigzag:
            // Continuous figure-8 pattern with slow drift
            let t = time * pad.speed * 0.3 + pad.phase
            let zigX = sin(t) * baseSpeed * 3
            let zigY = sin(t * 2) * baseSpeed * 2
            let driftX = cos(time * 0.07 + pad.phase) * baseSpeed * 1
            let driftY = sin(time * 0.05 + pad.phase * 1.5) * baseSpeed * 1
            return CGPoint(x: zigX + driftX, y: zigY + driftY)
            
        case .stillness:
            // Very subtle continuous wobble
            let dx = sin(time * 0.2 + pad.phase) * baseSpeed * 1.5
            let dy = cos(time * 0.15 + pad.phase) * baseSpeed * 1.5
            return CGPoint(x: dx, y: dy)
        }
    }

    private func addNewPad() {
        // Check if we have 5 pads and all are lotus (full pool)
        let hasFullPool = pads.count == 5 && pads.allSatisfy { $0.isLotus }
        
        if hasFullPool {
            // Start cycling through existing pads
            // Convert the current pad back to lily, then it will become lotus on next tap
            pads[cycleIndex].isLotus = false
            
            // Move to next pad for next cycle
            cycleIndex = (cycleIndex + 1) % 5
            
        } else if pads.isEmpty || pads.last?.isLotus == true {
            // Add a new lily pad (up to 5 max)
            if pads.count < 5 {
                // Find a position that's not too close to existing pads
                var position: CGPoint
                var attempts = 0
                let minSpacing: CGFloat = 0.16
                
                repeat {
                    position = randomPointInPool()
                    attempts += 1
                    
                    // Check if far enough from all existing pads
                    var isFarEnough = true
                    for existingPad in pads {
                        if distance(position, existingPad.anchor) < minSpacing {
                            isFarEnough = false
                            break
                        }
                    }
                    
                    if isFarEnough {
                        break
                    }
                } while attempts < 30
                
                let newPad = Pad(
                    anchor: position,
                    isLotus: false,
                    targetAnchor: randomPointInPool(),
                    movementStyle: MovementStyle.allCases.randomElement()!,
                    phase: CGFloat.random(in: 0...(2 * .pi)),
                    speed: CGFloat.random(in: 0.7...1.2)
                )
                pads.append(newPad)
            }
        } else {
            // Convert the last lily pad to lotus with glow effect
            pads[pads.count - 1].isLotus = true
            pads[pads.count - 1].glowIntensity = 1.0  // full glow
        }
    }
    
    // Make nearby lily pads bob when tapped
    private func bobNearbyPads(tapLocation: CGPoint) {
        for index in pads.indices {
            let dist = distance(pads[index].anchor, tapLocation)
            if dist < 0.2 {  // within range
                let strength = (0.2 - dist) / 0.2  // stronger when closer
                pads[index].bobVelocity = -3.0 * strength  // initial downward velocity
            }
        }
    }
    
    // Calculate distance between two points
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // Generate random point within the pool polygon
    private func randomPointInPool() -> CGPoint {
        // Generate points in the full bounding box and check if they're in the polygon
        var point: CGPoint
        var attempts = 0
        
        repeat {
            // Much tighter, very conservative bounds - center area only
            let x = CGFloat.random(in: 0.52...0.75)  // very centered
            let y = CGFloat.random(in: 0.77...0.85)  // middle area only, avoiding all edges
            point = CGPoint(x: x, y: y)
            attempts += 1
        } while !isPointInPoolPolygon(point, margin: 0.10) && attempts < 50  // increased margin
        
        // Fallback to safe center position if we can't find a valid point
        return attempts < 50 ? point : CGPoint(x: 0.63, y: 0.81)
    }
    
    // Check if point is inside the pool polygon with safety margin for pad size
    private func isPointInPoolPolygon(_ point: CGPoint, margin: CGFloat) -> Bool {
        // Pool polygon vertices (same as PoolWaterHitShape)
        let poolVertices: [CGPoint] = [
                    CGPoint(x: 0.53, y: 0.65),
                    CGPoint(x: 1.1, y: 0.73),
                    CGPoint(x: 1.0, y: 1.01),
                    CGPoint(x: 0.67, y: 0.92),
                    CGPoint(x: 0.21, y: 0.8)
                ]
        
        // Shrink polygon inward by margin to account for pad radius
        let shrunkenVertices = shrinkPolygon(poolVertices, by: margin)
        
        // Ray casting algorithm - count intersections with polygon edges
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
    
    // Shrink polygon inward by moving each vertex toward the centroid
    private func shrinkPolygon(_ vertices: [CGPoint], by margin: CGFloat) -> [CGPoint] {
        // Calculate centroid
        let centroid = vertices.reduce(CGPoint.zero) {
            CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)
        }
        let center = CGPoint(
            x: centroid.x / CGFloat(vertices.count),
            y: centroid.y / CGFloat(vertices.count)
        )
        
        // Move each vertex toward center
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
    
    // MARK: - Fireflies
    
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
        
        // Keep max 12 fireflies
        if fireflies.count > 12 {
            fireflies.removeFirst()
        }
    }
    
    private func updateFireflies(screenSize: CGSize) {
        for index in fireflies.indices {
            // Move firefly upward (opposite of falling particles)
            fireflies[index].position.y -= fireflies[index].speed
            
            // Horizontal drift and sway
            let sway = sin(time * 0.3 + CGFloat(index) * 0.4) * 0.6
            fireflies[index].position.x += fireflies[index].drift + sway
            
            // Twinkling effect
            let twinkle = sin(time * 2 + fireflies[index].twinklePhase) * 0.5 + 0.5
            fireflies[index].opacity = fireflies[index].baseOpacity * (0.5 + twinkle * 0.5)
            
            // Recycle when off screen (top)
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
    
    // Check if point is safely inside pool (with margin for pad size)
    private func isPointInPool(_ point: CGPoint) -> Bool {
        return isPointInPoolPolygon(point, margin: 0.10)  // increased from 0.07
    }
}

/// Hit area for the *water surface* (light-blue area).
/// Points are normalized (0...1). Tweak these if needed.
struct PoolWaterHitShape: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width,
                    y: rect.minY + y * rect.height)
        }

        // These points are set to the light-blue water region in your screenshot.
        // If it's still off on your device, tweak them with the debug stroke on.
        let pts: [CGPoint] = [
                    p(0.53, 0.65), // top-left of water
                    p(1.1, 0.73), // top-right of water
                    p(1.0, 1.01), // bottom-right (water goes to bottom edge in this image)
                    p(0.67, 0.92), // bottom-left of water (adjust if needed)
                    p(0.21, 0.8)  // left edge / perspective corner
                ]

        var path = Path()
        path.addLines(pts)
        path.closeSubpath()
        return path
    }

}
