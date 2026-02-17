//
//  LibraryView.swift
//  WhispersoftheGardenApp
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @Binding var showMainApp: Bool
    @State private var searchText = ""

    private var revealedPoems: [Poem] {
        revealedPoemsStore.getRevealedPoems()
    }

    private var revealedNightingaleCouplets: [Poem] {
        revealedPoemsStore.getRevealedNightingaleCouplets()
    }

    private var filteredPoems: [Poem] {
        if searchText.isEmpty {
            return revealedPoems
        }
        return revealedPoems.filter { poem in
            poem.persian.localizedCaseInsensitiveContains(searchText) ||
            poem.english.localizedCaseInsensitiveContains(searchText) ||
            poem.culturalNote.localizedCaseInsensitiveContains(searchText) ||
            poem.reflection.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredNightingaleCouplets: [Poem] {
        if searchText.isEmpty {
            return revealedNightingaleCouplets
        }
        return revealedNightingaleCouplets.filter { poem in
            poem.persian.localizedCaseInsensitiveContains(searchText) ||
            poem.english.localizedCaseInsensitiveContains(searchText) ||
            poem.culturalNote.localizedCaseInsensitiveContains(searchText) ||
            poem.reflection.localizedCaseInsensitiveContains(searchText)
        }
    }

    // App palette
    private let bgColor = Color(red: 0.02, green: 0.08, blue: 0.18)
    private let cardColor = Color.white.opacity(0.07)
    private let rose = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let gold = Color(red: 1.0, green: 0.85, blue: 0.55)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if revealedPoems.isEmpty && revealedNightingaleCouplets.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if !filteredPoems.isEmpty {
                            sectionHeader(
                                icon: "LotusFull",
                                title: "From the Lotus",
                                subtitle: "Verses that bloomed from the pool",
                                count: revealedPoems.count,
                                total: revealedPoemsStore.totalPoemsCount
                            )

                            ForEach(filteredPoems) { poem in
                                NavigationLink(destination: PoemDetailView(poem: poem)) {
                                    poemCard(poem)
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .combine)
                                .accessibilityHint("Double tap to view full poem")
                            }
                        }

                        if !filteredNightingaleCouplets.isEmpty {
                            sectionHeader(
                                icon: "Nightingale02",
                                title: "From the Nightingale",
                                subtitle: "Couplets gifted by the garden's songbird",
                                count: revealedNightingaleCouplets.count,
                                total: NightingaleCouplets.couplets.count
                            )
                            .padding(.top, filteredPoems.isEmpty ? 0 : 12)

                            ForEach(filteredNightingaleCouplets) { couplet in
                                NavigationLink(destination: PoemDetailView(poem: couplet)) {
                                    poemCard(couplet)
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .combine)
                                .accessibilityHint("Double tap to view full couplet")
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search poems...")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String, subtitle: String, count: Int, total: Int) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(gold)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()

                Text("\(count) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [rose, gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(count) / CGFloat(max(1, total)),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(count) of \(total) revealed")
    }

    // MARK: - Poem Card

    private func poemCard(_ poem: Poem) -> some View {
        VStack(spacing: 10) {
            Text(poem.poet)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(rose.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.5)

            Text(poem.persian)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineLimit(3)

            Text(poem.english)
                .font(.system(size: 14, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(rose.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(rose.opacity(0.4))

            VStack(spacing: 8) {
                Text("No Poems Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))

                Text("Tap the pool in your garden\nto reveal hidden verses")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No poems yet. Tap the pool in your garden to reveal hidden verses.")
    }
}
