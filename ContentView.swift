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
    @State private var gardenReady = false       // garden view exists in the hierarchy
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

                // Garden fades in/out on top of landing page
                if gardenReady {
                    MainAppView(showMainApp: $gardenReady)
                        .environmentObject(revealedPoemsStore)
                        .opacity(gardenOpacity)
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
        .onChange(of: gardenReady) { newValue in
            // Back button pressed from garden/library — play exit transition
            if !newValue && !isTransitioning {
                gardenReady = true // keep alive while we transition
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
                gardenReady = true
                gardenOpacity = 1.0
                landingVisible = false
                try? await Task.sleep(for: .milliseconds(400))
                isTransitioning = false
            } else {
                // Phase 1: Petals sweep in
                try? await Task.sleep(for: .milliseconds(700))

                // Phase 2: Create garden, cross-dissolve in
                gardenReady = true
                gardenOpacity = 0

                withAnimation(.easeInOut(duration: 0.8)) {
                    gardenOpacity = 1.0
                }

                // Phase 3: Remove landing page
                try? await Task.sleep(for: .milliseconds(900))
                landingVisible = false

                // Phase 4: Petals finish drifting
                try? await Task.sleep(for: .milliseconds(800))
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
                gardenReady = false
                try? await Task.sleep(for: .milliseconds(400))
                isTransitioning = false
            } else {
                // Phase 1: Petals sweep in
                try? await Task.sleep(for: .milliseconds(700))

                // Phase 2: Cross-dissolve garden out, bring landing back
                landingVisible = true

                withAnimation(.easeInOut(duration: 0.8)) {
                    gardenOpacity = 0
                }

                // Phase 3: Remove garden
                try? await Task.sleep(for: .milliseconds(900))
                gardenReady = false

                // Phase 4: Petals finish drifting
                try? await Task.sleep(for: .milliseconds(800))
                isTransitioning = false
            }
        }
    }
}
