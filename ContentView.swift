//
//  ContentView.swift - WITH PETAL TRANSITIONS
//  WhispersoftheGardenApp
//

import SwiftUI

struct ContentView: View {
    @StateObject private var revealedPoemsStore = RevealedPoemsStore()
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private let audio = GardenAudioEngine.shared
    @State private var showMainApp = false       // one-shot trigger from LandingPage
    @State private var showOptions = false
    @State private var isTransitioning = false
    @State private var gardenCreated = false     // once true, stays true — keeps view alive
    @State private var showGarden = false        // home button binding — triggers exit transition
    @State private var gardenOpacity: Double = 0 // cross-fade control
    @State private var landingVisible = true     // keep landing alive during cross-fade

    var body: some View {
        ZStack {
            // Landing page stays alive until cross-fade finishes
            if landingVisible {
                LandingPage(showMainApp: $showMainApp, showOptions: $showOptions)
                    .environmentObject(revealedPoemsStore)
                    .allowsHitTesting(!showOptions)
            }

            // Garden persists once created — only opacity changes
            if gardenCreated {
                MainAppView(showMainApp: $showGarden)
                    .environmentObject(revealedPoemsStore)
                    .opacity(gardenOpacity)
                    .allowsHitTesting(gardenOpacity > 0)
            }

            // Petal overlay — always in tree, paused when inactive
            PetalTransitionView(reduceMotion: reduceMotion, isActive: isTransitioning)

            // Options overlays on top — landing page stays intact underneath
            if showOptions {
                OptionsView(showOptions: $showOptions)
                    .environmentObject(revealedPoemsStore)
            }
        }
        .onChange(of: showMainApp) { newValue in
            // Enter garden trigger
            if newValue {
                showMainApp = false
                beginEnterTransition()
            }
        }
        .onChange(of: showGarden) { newValue in
            // Back button pressed from garden/library — play exit transition
            if !newValue && !isTransitioning {
                beginHomeTransition()
            }
        }
        .animation(nil, value: showMainApp)
        .onAppear {
            audio.startEngine()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                audio.startEngine()
            case .background:
                audio.stopEngine()
            default:
                break
            }
        }
    }

    // MARK: - Enter Garden

    private func beginEnterTransition() {
        guard !isTransitioning else { return }
        isTransitioning = true

        Task { @MainActor in
            audio.playSFX(.petalWhoosh)

            // Pre-create the garden view (hidden) so all assets, Metal
            // pipelines, and state initialize before the transition starts.
            if !gardenCreated {
                gardenCreated = true
                gardenOpacity = 0
                // Give SwiftUI a frame to instantiate the view tree
                try? await Task.sleep(for: .milliseconds(50))
            }

            if reduceMotion {
                // Instant cross-fade with brief overlay
                try? await Task.sleep(for: .milliseconds(100))
                showGarden = true
                gardenOpacity = 1.0
                landingVisible = false
                try? await Task.sleep(for: .milliseconds(400))
                isTransitioning = false
            } else {
                // Phase 1: Petals sweep in
                try? await Task.sleep(for: .milliseconds(350))

                // Phase 2: Cross-dissolve garden in
                showGarden = true

                withAnimation(.easeInOut(duration: 0.5)) {
                    gardenOpacity = 1.0
                }

                // Phase 3: Remove landing page
                try? await Task.sleep(for: .milliseconds(550))
                landingVisible = false

                // Phase 4: Let petals finish their full animation
                try? await Task.sleep(for: .milliseconds(650))
                isTransitioning = false
            }
        }
    }

    // MARK: - Go Home

    private func beginHomeTransition() {
        guard !isTransitioning else { return }
        isTransitioning = true

        Task { @MainActor in
            audio.playSFX(.petalWhoosh)

            if reduceMotion {
                // Instant cross-fade with brief overlay
                try? await Task.sleep(for: .milliseconds(100))
                landingVisible = true
                gardenOpacity = 0
                try? await Task.sleep(for: .milliseconds(400))
                isTransitioning = false
            } else {
                // Phase 1: Petals sweep in
                try? await Task.sleep(for: .milliseconds(350))

                // Phase 2: Cross-dissolve garden out, bring landing back
                landingVisible = true

                withAnimation(.easeInOut(duration: 0.5)) {
                    gardenOpacity = 0
                }

                // Phase 3: Garden stays alive but hidden (gardenCreated stays true)
                try? await Task.sleep(for: .milliseconds(550))

                // Phase 4: Let petals finish their full animation
                try? await Task.sleep(for: .milliseconds(650))
                isTransitioning = false
            }
        }
    }
}
