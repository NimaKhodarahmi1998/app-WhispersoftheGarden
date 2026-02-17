//
//  MainAppView.swift - WITH PERSIAN TAB BAR
//  WhispersoftheGardenApp
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @Binding var showMainApp: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var selectedTab = 0
    @State private var isTabTransitioning = false
    @State private var pendingTab: Int? = nil
    @State private var windDirection: PetalWindDirection = .rightToLeft

    // Persian palette
    private let gold = Color(red: 1.0, green: 0.92, blue: 0.65)
    private let darkGold = Color(red: 0.92, green: 0.78, blue: 0.48)
    private let dimGold = Color(red: 0.7, green: 0.6, blue: 0.4)
    private let rose = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let deepBlue = Color(red: 0.03, green: 0.08, blue: 0.18)
    private let lighterBlue = Color(red: 0.06, green: 0.13, blue: 0.26)

    var body: some View {
        ZStack {
            // Content
            Group {
                if selectedTab == 0 {
                    GardenView(showMainApp: $showMainApp)
                } else {
                    NavigationStack {
                        LibraryView(showMainApp: $showMainApp)
                    }
                }
            }

            // Petal transition overlay with wind direction
            if isTabTransitioning {
                PetalTransitionView(wind: windDirection, reduceMotion: reduceMotion)
            }

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
        guard tab != selectedTab && !isTabTransitioning else { return }

        if reduceMotion {
            selectedTab = tab
            return
        }

        // Garden(0) → Library(1): wind blows right to left
        // Library(1) → Garden(0): wind blows left to right
        windDirection = tab > selectedTab ? .rightToLeft : .leftToRight
        pendingTab = tab
        isTabTransitioning = true

        Task { @MainActor in
            // Petals cover the screen
            try? await Task.sleep(for: .milliseconds(700))

            // Switch underneath
            if let tab = pendingTab {
                selectedTab = tab
                pendingTab = nil
            }

            // Petals drift away
            try? await Task.sleep(for: .milliseconds(1700))
            isTabTransitioning = false
        }
    }
}
