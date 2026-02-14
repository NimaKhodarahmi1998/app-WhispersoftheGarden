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

                // Tap zone (your pool water shape)
                PoolWaterHitShape()
                    .fill(.clear)
                    .contentShape(PoolWaterHitShape())
                    .onTapGesture {
                        // 1) show poem
                        currentPoem = PoemLibrary.poems.randomElement()
                        showPoem = (currentPoem != nil)

                        // 2) add a new pad
                        addNewPad()
                    }

                // Optional: debug the pool hit shape
                // PoolWaterHitShape()
                //     .stroke(.white.opacity(0.8), lineWidth: 2)

                // Render pads (on top of the water)
                ForEach(pads) { pad in
                    let size = geo.size.width * 0.12
                    let half = size / 2

                    let rawX = pad.anchor.x * geo.size.width
                    let rawY = pad.anchor.y * geo.size.height

                    let x = min(max(rawX, half), geo.size.width - half)
                    let y = min(max(rawY, half), geo.size.height - half)

                    Image(pad.isLotus ? "LotusFull" : "LilyPad")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .position(x: x, y: y)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 2.5), value: pad.anchor)  // increased from 1.2 for slower, dreamier movement
                        .animation(.easeInOut(duration: 0.5), value: pad.isLotus)  // Smooth transformation
                }

                if showPoem, let poem = currentPoem {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showPoem = false
                            currentPoem = nil
                        }

                    PoemOverlayView(
                        persian: poem.persian,
                        english: poem.english,
                        culturalNote: poem.culturalNote,
                        reflection: poem.reflection
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(), value: showPoem)
        }
        .ignoresSafeArea()
        .onReceive(timer) { _ in
            time += 0.05
            
            for index in pads.indices {
                let pad = pads[index]
                
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
                if distToTarget < 0.04 || Int(time * 20) % 200 == index * 40 {  // reach target OR every ~10 seconds per pad
                    pads[index].targetAnchor = randomPointInPool()
                    // Occasionally change movement style for variety
                    if Double.random(in: 0...1) < 0.15 {
                        pads[index].movementStyle = MovementStyle.allCases.randomElement()!
                        pads[index].phase = CGFloat.random(in: 0...(2 * .pi))
                    }
                }
            }
        }
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
                    speed: CGFloat.random(in: 0.7...1.2)  // reduced range from 0.5...1.5 for more uniform speed
                )
                pads.append(newPad)
            }
        } else {
            // Convert the last lily pad to lotus
            pads[pads.count - 1].isLotus = true
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
