//
//  MainAppView.swift - WITH PERSIAN TAB BAR
//  WhispersoftheGardenApp
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @Binding var showMainApp: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    private let audio = GardenAudioEngine.shared

    @State private var selectedTab = 0
    @State private var isTabTransitioning = false
    @State private var pendingTab: Int? = nil
    @State private var windDirection: PetalWindDirection = .rightToLeft
    @State private var libraryNavPath = NavigationPath()

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
                .opacity(selectedTab == 0 ? 1 : 0)
                .allowsHitTesting(selectedTab == 0 && !isTabTransitioning)

            // Library — always alive (no creation spike on tab switch), paused when off-screen
            NavigationStack(path: $libraryNavPath) {
                LibraryView(showMainApp: $showMainApp, isActive: selectedTab == 1 && showMainApp && !isTabTransitioning)
            }
            .opacity(selectedTab == 1 ? 1 : 0)
            .allowsHitTesting(selectedTab == 1 && !isTabTransitioning)

            // Petal transition overlay — always in tree, paused when inactive
            PetalTransitionView(wind: windDirection, reduceMotion: reduceMotion, isActive: isTabTransitioning)

            // Persian tab bar
            VStack {
                Spacer()
                persianTabBar
            }
        }
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
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isActive ? gold : .white.opacity(0.7))
                .shadow(color: isActive ? gold.opacity(0.6) : .clear, radius: 8)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    // MARK: - Tab Transition

    private func switchTab(to tab: Int) {
        guard !isTabTransitioning else { return }

        // Re-tap library while already on library → pop to root
        if tab == selectedTab {
            if tab == 1 && !libraryNavPath.isEmpty {
                audio.playSFX(.gentleTap)
                withAnimation { libraryNavPath = NavigationPath() }
            }
            return
        }

        Haptics.tabSwitch()

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
