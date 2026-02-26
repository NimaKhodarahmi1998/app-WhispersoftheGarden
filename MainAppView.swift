//
//  MainAppView.swift - WITH PERSIAN TAB BAR
//  WhispersoftheGardenApp
//

import SwiftUI

private struct TabFrameKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct MainAppView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @StateObject private var hintStore = GardenHintStore()
    @Binding var showMainApp: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    private let audio = GardenAudioEngine.shared

    @State private var selectedTab = 0
    @State private var isTabTransitioning = false
    @State private var pendingTab: Int? = nil
    @State private var windDirection: PetalWindDirection = .rightToLeft
    @State private var libraryNavID = UUID()
    @State private var tabFrames: [Int: CGRect] = [:]
    @ScaledMetric(relativeTo: .body) private var tabIconSize: CGFloat = 22

    // Persian palette (centralized in PersianColors)
    private let gold = Color.gardenGold
    private let darkGold = Color.gardenDarkGold
    private let dimGold = Color.gardenDimGold
    private let rose = Color.gardenRose
    private let deepBlue = Color.gardenDeepBlue
    private let lighterBlue = Color.gardenLighterBlue

    var body: some View {
        ZStack {
            // Garden — always alive, paused when off-screen
            GardenView(showMainApp: $showMainApp, isActive: selectedTab == 0 && showMainApp && !isTabTransitioning)
                .environmentObject(hintStore)
                .opacity(selectedTab == 0 ? 1 : 0)
                .allowsHitTesting(selectedTab == 0 && !isTabTransitioning)

            // Library — always alive (no creation spike on tab switch), paused when off-screen
            NavigationStack {
                LibraryView(showMainApp: $showMainApp, isActive: selectedTab == 1 && showMainApp && !isTabTransitioning)
                    .environmentObject(hintStore)
            }
            .id(libraryNavID)
            .opacity(selectedTab == 1 ? 1 : 0)
            .allowsHitTesting(selectedTab == 1 && !isTabTransitioning)

            // Petal transition overlay — always in tree, paused when inactive
            PetalTransitionView(wind: windDirection, reduceMotion: reduceMotion, isActive: isTabTransitioning)

            // "Visit library" spotlight — over garden, pointing at library button
            if hintStore.activeHint == .visitLibrary, selectedTab == 0,
               let frame = tabFrames[1] {
                tabSpotlightOverlay(
                    buttonCenter: CGPoint(x: frame.midX, y: frame.midY),
                    text: "Your verses are kept in the library",
                    color: Color.persianSaffron
                )
            }

            // "Return to garden" spotlight — over library, pointing at garden button
            if hintStore.activeHint == .returnToGarden, selectedTab == 1,
               let frame = tabFrames[0] {
                tabSpotlightOverlay(
                    buttonCenter: CGPoint(x: frame.midX, y: frame.midY),
                    text: "The garden awaits your return",
                    color: Color.persianTurquoise
                )
            }

            // Persian tab bar
            VStack {
                Spacer()
                persianTabBar
            }
        }
        .coordinateSpace(name: "mainApp")
        .onPreferenceChange(TabFrameKey.self) { tabFrames = $0 }
    }

    // MARK: - Tab Spotlight Overlay

    private func tabSpotlightOverlay(buttonCenter: CGPoint, text: String, color: Color) -> some View {
        GeometryReader { geo in
            let unitCenter = UnitPoint(
                x: buttonCenter.x / geo.size.width,
                y: buttonCenter.y / geo.size.height
            )
            ZStack {
                // Dark vignette with clear center on the button
                RadialGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.55)
                    ],
                    center: unitCenter,
                    startRadius: 30,
                    endRadius: 250
                )
                .ignoresSafeArea()

                // Bright glow halo around button
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.45),
                                color.opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)
                    .position(buttonCenter)

                // Pulsing ring around button
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .frame(width: 56, height: 56)
                    .position(buttonCenter)

                // Text pill above the tab bar
                Text(text)
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color.opacity(0.85)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.65))
                            .overlay(
                                Capsule()
                                    .strokeBorder(color.opacity(0.35), lineWidth: 1)
                            )
                    )
                    .shadow(color: color.opacity(0.5), radius: 16)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    .position(x: geo.size.width * 0.5, y: buttonCenter.y - 70)
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - Floating Navigation

    private var persianTabBar: some View {
        HStack(spacing: 20) {
            floatingIcon(icon: "house.fill", tab: -1)
            floatingIcon(icon: "leaf.fill", tab: 0)
            floatingIcon(icon: "book.fill", tab: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(deepBlue.opacity(0.75))
        )
        .padding(.bottom, 20)
    }

    private func floatingIcon(icon: String, tab: Int) -> some View {
        let isActive = tab >= 0 && selectedTab == tab

        let label: String
        let hint: String
        switch tab {
        case -1:
            label = "Home"
            hint = "Returns to the landing page"
        case 0:
            label = "Garden"
            hint = "Opens the garden"
        default:
            label = "Library"
            hint = "Opens the poem library"
        }

        return Button {
            if tab == -1 {
                audio.playSFX(.gentleTap)
                showMainApp = false
            } else {
                switchTab(to: tab)
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: tabIconSize, weight: .medium))
                .foregroundStyle(isActive ? gold : .white.opacity(0.7))
                .shadow(color: isActive ? gold.opacity(0.6) : .clear, radius: 8)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: TabFrameKey.self,
                            value: [tab: geo.frame(in: .named("mainApp"))]
                        )
                    }
                )
        }
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    // MARK: - Tab Transition

    /// Whether the user is allowed to switch to the given tab right now.
    private func canSwitchTo(_ tab: Int) -> Bool {
        guard !hintStore.isTutorialComplete else { return true }
        let hint = hintStore.activeHint
        if tab == 1 {
            // Can only go to library once visitLibrary (or later) is the active hint
            return hint == .visitLibrary || hint == .exploreLibrary || hint == .returnToGarden
        }
        if tab == 0 {
            // Can only return to garden once returnToGarden is the active hint (or tutorial done)
            return hint == .returnToGarden
        }
        return true
    }

    private func switchTab(to tab: Int) {
        guard !isTabTransitioning else { return }

        // Re-tap library while already on library → pop to root
        if tab == selectedTab {
            if tab == 1 {
                audio.playSFX(.gentleTap)
                libraryNavID = UUID()
            }
            return
        }

        // Block tab switch if the user hasn't reached this tutorial step yet
        guard canSwitchTo(tab) else { return }

        Haptics.tabSwitch()

        // Track onboarding progress on tab switch
        if tab == 1 { hintStore.markLibraryVisited() }
        if tab == 0 && hintStore.hasEverExploredLibrary { hintStore.markReturnedToGarden() }

        if reduceMotion {
            selectedTab = tab
            return
        }

        // Garden(0) → Library(1): wind blows right to left
        // Library(1) → Garden(0): wind blows left to right
        windDirection = tab > selectedTab ? .rightToLeft : .leftToRight
        pendingTab = tab
        isTabTransitioning = true
        audio.playSFX(.petalWhoosh)

        Task { @MainActor in
            // Petals sweep in — at 300ms they're at peak density
            try? await Task.sleep(for: .milliseconds(300))

            // Cross-fade underneath the petals (both views already in tree — just opacity)
            if let tab = pendingTab {
                withAnimation(.easeInOut(duration: 0.4)) {
                    selectedTab = tab
                }
                pendingTab = nil
            }

            // Let petals finish their animation
            try? await Task.sleep(for: .milliseconds(900))
            isTabTransitioning = false
        }
    }
}
