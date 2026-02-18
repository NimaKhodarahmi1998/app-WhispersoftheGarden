//
//  ContentView.swift - WITH PETAL TRANSITIONS
//  WhispersoftheGardenApp
//

import SwiftUI

struct ContentView: View {
    @StateObject private var revealedPoemsStore = RevealedPoemsStore()
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var showMainApp = false       // one-shot trigger from LandingPage
    @State private var showOptions = false
    @State private var isTransitioning = false
    @State private var gardenCreated = false     // once true, stays true — keeps view alive
    @State private var showGarden = false        // home button binding — triggers exit transition
    @State private var gardenOpacity: Double = 0 // cross-fade control
    @State private var landingVisible = true     // keep landing alive during cross-fade

    var body: some View {
        ZStack {
            if showOptions {
                OptionsView(showOptions: $showOptions)
                    .environmentObject(revealedPoemsStore)
            } else {
                // Landing page stays alive until cross-fade finishes
                if landingVisible {
                    LandingPage(showMainApp: $showMainApp, showOptions: $showOptions)
                        .environmentObject(revealedPoemsStore)
                }

                // Garden persists once created — only opacity changes
                if gardenCreated {
                    MainAppView(showMainApp: $showGarden)
                        .environmentObject(revealedPoemsStore)
                        .opacity(gardenOpacity)
                        .allowsHitTesting(gardenOpacity > 0)
                }

                // Petal overlay on top of everything
                if isTransitioning {
                    PetalTransitionView(reduceMotion: reduceMotion)
                }
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
    }

    // MARK: - Enter Garden

    private func beginEnterTransition() {
        guard !isTransitioning else { return }
        isTransitioning = true

        Task { @MainActor in
            if reduceMotion {
                // Instant cross-fade with brief overlay
                try? await Task.sleep(for: .milliseconds(100))
                gardenCreated = true
                showGarden = true
                gardenOpacity = 1.0
                landingVisible = false
                try? await Task.sleep(for: .milliseconds(400))
                isTransitioning = false
            } else {
                // Phase 1: Petals build up
                try? await Task.sleep(for: .milliseconds(900))

                // Phase 2: Show garden, cross-dissolve in
                gardenCreated = true
                showGarden = true
                gardenOpacity = 0

                withAnimation(.easeInOut(duration: 1.0)) {
                    gardenOpacity = 1.0
                }

                // Phase 3: Remove landing page
                try? await Task.sleep(for: .milliseconds(1100))
                landingVisible = false

                // Phase 4: Petals finish drifting
                try? await Task.sleep(for: .milliseconds(1000))
                isTransitioning = false
            }
        }
    }

    // MARK: - Go Home

    private func beginHomeTransition() {
        guard !isTransitioning else { return }
        isTransitioning = true

        Task { @MainActor in
            if reduceMotion {
                // Instant cross-fade with brief overlay
                try? await Task.sleep(for: .milliseconds(100))
                landingVisible = true
                gardenOpacity = 0
                try? await Task.sleep(for: .milliseconds(400))
                isTransitioning = false
            } else {
                // Phase 1: Petals build up
                try? await Task.sleep(for: .milliseconds(900))

                // Phase 2: Cross-dissolve garden out, bring landing back
                landingVisible = true

                withAnimation(.easeInOut(duration: 1.0)) {
                    gardenOpacity = 0
                }

                // Phase 3: Garden stays alive but hidden (gardenCreated stays true)
                try? await Task.sleep(for: .milliseconds(1100))

                // Phase 4: Petals finish drifting
                try? await Task.sleep(for: .milliseconds(1000))
                isTransitioning = false
            }
        }
    }
}
