import SwiftUI

struct GardenView: View {
    @State private var showPoem = false
    @State private var currentPoem: Poem?

    var body: some View {
        
        
        ZStack {
            Image("GardenView")
                .resizable()
                .ignoresSafeArea()

            GeometryReader { _ in
                // Invisible tappable layer, shaped like the LIGHT-BLUE water area
                PoolWaterHitShape()
                    .fill(.clear)
                    .contentShape(PoolWaterHitShape())
                    .onTapGesture {
                        currentPoem = PoemLibrary.poems.randomElement()
                        showPoem = (currentPoem != nil)
                    }

                // ✅ Debug: show the hit shape so you can adjust points
                // PoolWaterHitShape()
                //     .stroke(.white.opacity(0.8), lineWidth: 2)
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
            }
        }
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
        // If it’s still off on your device, tweak them with the debug stroke on.
        let pts: [CGPoint] = [
            p(0.53, 0.65), // top-left of water
            p(1.0, 0.73), // top-right of water
            p(1.0, 1.04), // bottom-right (water goes to bottom edge in this image)
            p(0.6, 0.919), // bottom-left of water (adjust if needed)
            p(0.24, 0.817)  // left edge / perspective corner
        ]

        var path = Path()
        path.addLines(pts)
        path.closeSubpath()
        return path
    }
}


