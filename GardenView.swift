import SwiftUI

struct GardenView: View {

    // MARK: - State
    @State private var breathe = false
    @State private var seedActive = false
    @State private var seedPressed = false
    @State private var plantingPulse = false
    @State private var showPoem = false
    @State private var currentPoem: Poem?
    @State private var revisitingPoem = false
    @State private var discoveredPoemsID: Set<UUID> = []
    @State private var afterglow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Timing
    private let tapToOverlayDelay: Double = 0.38
    private let pulseDuration: Double = 0.28
    private let pressReleaseDelay: Double = 0.18

    // MARK: - Derived state
    private var growthLevel: Int { discoveredPoemsID.count }

    private var glowOpacity: Double {
        if !breathe { return 0.08 }
        if afterglow { return 0.14}
        if revisitingPoem { return 0.10 }
        return 0.12 + Double(growthLevel) * 0.03
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack {
                Spacer()

                glowCircle

                seedButton

                groundPanel
            }
            .padding(.bottom, 24)

            gardenElementsLayer
                .allowsHitTesting(false)

            poemOverlay
        }
        .onAppear(perform: handleAppear)
        .onChange(of: discoveredPoemsID) { newValue in
            GardenProgressStore.save(newValue)
        }
    }
}

// MARK: - Subviews
private extension GardenView {

    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.persianIndigo, .persianTurquoise]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var glowCircle: some View {
        Circle()
            .foregroundStyle(Color.persianGold.opacity(0.14))
            .frame(width: 320, height: 320)
            .blur(radius: 70)
            .scaleEffect(breathe ? 1.03 : 0.97)
            .opacity(glowOpacity)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 8).repeatForever(autoreverses: true),
                value: breathe
            )
    }

    var seedButton: some View {
        Circle()
            .foregroundStyle(Color.persianTurquoise.opacity(0.35))
            .frame(width: 80, height: 80)
            .overlay(
                Circle().stroke(Color.persianGold.opacity(0.6), lineWidth: 1.5)
            )
            .scaleEffect(seedPressed ? 0.95 : (plantingPulse ? 1.08 : 1.0))
            .opacity(seedActive ? 1.0 : 0.7)
            .animation(reduceMotion ? .none: .easeInOut(duration: 0.18), value: seedPressed)
            .animation(reduceMotion ? .none: .easeInOut(duration: pulseDuration), value: plantingPulse)
            .animation(reduceMotion ? .none: .easeInOut(duration: 0.25), value: seedActive)
            .onTapGesture(perform: handleSeedTap)
            .onLongPressGesture(minimumDuration: 0.6, perform: handleSeedLongPress)
    }

    var groundPanel: some View {
        RoundedRectangle(cornerRadius: 42, style: .continuous)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.persianSand, .persianSaffron]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 360)
            .scaleEffect(breathe ? 1.01 : 0.99)
            .opacity(breathe ? 1.0 : 0.96)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 6).repeatForever(autoreverses: true),
                value: breathe
            )
    }

    var gardenElementsLayer: some View {
        VStack {
            Spacer()

            ZStack {
                // Debug (remove for submission)
                Text("growth: \(growthLevel)")
                    .foregroundStyle(.white)
                    .font(.caption)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding()

                GardenElementView(imageName: "Plant",  isVisible: growthLevel >= 1, size: 60, step: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 48)

                GardenElementView(imageName: "Flower", isVisible: growthLevel >= 2, size: 84, step: 2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 48)

                GardenElementView(imageName: "Water",  isVisible: growthLevel >= 3, size: 76, step: 3)

                GardenElementView(imageName: "Stone",  isVisible: growthLevel >= 4, size: 96, step: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 92)
                    .padding(.top, 44)
            }

            Spacer(minLength: 140)
        }
    }

    @ViewBuilder
    var poemOverlay: some View {
        if showPoem, let poem = currentPoem {
            ZStack {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.22)) {
                            showPoem = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            revisitingPoem = false
                            currentPoem = nil
                            afterglow = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                afterglow = false}
                        }
                    }

                PoemOverlayView(
                    persian: poem.persian,
                    english: poem.english,
                    culturalNote: poem.culturalNote,
                    reflection: poem.reflection
                )
                .zIndex(10)
            }
        }
    }
}

// MARK: - Actions
private extension GardenView {

    func handleAppear() {
        if discoveredPoemsID.isEmpty {
            discoveredPoemsID = GardenProgressStore.load()
        }
        if !breathe { breathe = true }
    }

    func handleSeedTap() {
        guard !showPoem else { return }
        guard let randomPoem = PoemLibrary.poems.randomElement() else { return }

        let isNewPoem = !discoveredPoemsID.contains(randomPoem.id)

        currentPoem = randomPoem
        revisitingPoem = !isNewPoem

        if isNewPoem {
            discoveredPoemsID.insert(randomPoem.id)
        }

        seedActive = true
        plantingPulse = true

        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration) {
            plantingPulse = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            seedActive = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + tapToOverlayDelay) {
            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
                showPoem = true
            }
        }
    }

    func handleSeedLongPress() {
        guard !showPoem else { return }

        seedPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            seedPressed = false
        }
    }
}
