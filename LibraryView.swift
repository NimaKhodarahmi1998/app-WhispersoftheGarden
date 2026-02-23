//
//  LibraryView.swift
//  WhispersoftheGardenApp
//

import SwiftUI

// MARK: - Poet Biography

private struct PoetBio: Identifiable {
    let id: String        // matches Poem.poet
    let name: String
    let years: String
    let homeland: String
    let bio: String

    static let all: [PoetBio] = [
        PoetBio(
            id: "Saadi",
            name: "Saadi Shirazi",
            years: "c. 1210 – 1292",
            homeland: "Shiraz, Persia",
            bio: "Saadi left Shiraz as a young man and spent thirty years wandering through Baghdad, Damascus, Egypt, and beyond — sometimes as a student, sometimes as a prisoner of war. He came home and distilled everything he'd seen into the Golestan and Bustan, two books so full of practical wisdom and humanity that they became the most widely read works in the Persian language. His verse on human unity is carved at the entrance of the United Nations."
        ),
        PoetBio(
            id: "Hafez",
            name: "Hafez Shirazi",
            years: "c. 1315 – 1390",
            homeland: "Shiraz, Persia",
            bio: "Hafez never left Shiraz, but Shiraz came to contain the whole world inside his poetry. He mastered the ghazal — a short lyric form — and used it to say things nobody else could get away with: love poems that were also prayers, drinking songs that were also philosophy, praise of beauty that quietly mocked the powerful. Iranians still open his Divan at random to seek guidance, a tradition called faal-e Hafez. Seven centuries later, he remains the most beloved poet in Iran."
        ),
        PoetBio(
            id: "Khayyam",
            name: "Omar Khayyam",
            years: "1048 – 1131",
            homeland: "Nishapur, Persia",
            bio: "Before he ever wrote a quatrain, Khayyam was one of the great mathematicians and astronomers of his age. He solved cubic equations, classified their geometric solutions, and calculated the length of the solar year with extraordinary precision. Then he turned that same clear-eyed mind toward the brevity of life and wrote the Rubaiyat — short, luminous poems about wine, time, and the strangeness of being alive at all. He didn't mourn impermanence. He marveled at it."
        ),
        PoetBio(
            id: "Rumi",
            name: "Jalal al-Din Rumi",
            years: "1207 – 1273",
            homeland: "Balkh (present-day Afghanistan)",
            bio: "Rumi was a respected theologian and scholar in Konya until the wandering dervish Shams-e Tabrizi walked into his life and turned everything upside down. He abandoned his lectern, his reputation, his composure — and in the wreckage he found a voice that would produce the Masnavi, a 25,000-couplet spiritual epic he dictated while pacing, weeping, and sometimes dancing. He founded the Mevlevi order, whose whirling ceremony became one of the most recognizable images of Sufism. He is now the best-selling poet in the United States."
        ),
        PoetBio(
            id: "Ferdowsi",
            name: "Abolqasem Ferdowsi",
            years: "c. 940 – 1020",
            homeland: "Tus, Persia",
            bio: "Ferdowsi spent over thirty years writing the Shahnameh — the Book of Kings — a 50,000-couplet epic that traces Iranian civilization from the creation of the world to the Arab conquest. He did it almost entirely alone, selling off his land to fund the work, because the Persian language was being swallowed by Arabic and he refused to let a civilization's memory disappear. The Shahnameh preserved not just stories but the language itself. Modern Persian exists in large part because one man in a village near Tus decided it was worth his entire life to save it."
        )
    ]
}

struct LibraryView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @Binding var showMainApp: Bool
    var isActive: Bool = true  // pause particles when off-screen
    private let audio = GardenAudioEngine.shared
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var selectedPoet: String? = nil
    @State private var showFavoritesOnly = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // Dynamic Type scaled font sizes
    @ScaledMetric(relativeTo: .caption2) private var tinySize: CGFloat = 12
    @ScaledMetric(relativeTo: .caption) private var smallSize: CGFloat = 13
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14
    @ScaledMetric(relativeTo: .footnote) private var footnoteSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) private var chipSize: CGFloat = 15
    @ScaledMetric(relativeTo: .subheadline) private var bodySmallSize: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 19
    @ScaledMetric(relativeTo: .headline) private var headlineSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var tileMinHeight: CGFloat = 200

    // All poems (revealed + locked)
    private var allPoems: [Poem] { PoemLibrary.poems }
    private var allNightingaleCouplets: [Poem] { NightingaleCouplets.couplets }

    // Filtered poems (applies poet → favorites → search)
    private var filteredPoems: [Poem] {
        var result = allPoems

        if let poet = selectedPoet {
            result = result.filter { $0.poet == poet }
        }

        if showFavoritesOnly {
            result = result.filter { revealedPoemsStore.isFavorite($0) }
        }

        if !debouncedSearch.isEmpty {
            result = result.filter { poem in
                if revealedPoemsStore.isRevealed(poem) {
                    return poem.poet.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.persian.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.english.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.culturalNote.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.reflection.localizedCaseInsensitiveContains(debouncedSearch)
                } else {
                    // Locked: only match poet name
                    return poem.poet.localizedCaseInsensitiveContains(debouncedSearch)
                }
            }
        }

        return result
    }

    private var filteredNightingaleCouplets: [Poem] {
        var result = allNightingaleCouplets

        if let poet = selectedPoet {
            result = result.filter { $0.poet == poet }
        }

        if showFavoritesOnly {
            result = result.filter { revealedPoemsStore.isFavorite($0) }
        }

        if !debouncedSearch.isEmpty {
            result = result.filter { poem in
                if revealedPoemsStore.revealedNightingaleIDs.contains(poem.id) {
                    return poem.poet.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.persian.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.english.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.culturalNote.localizedCaseInsensitiveContains(debouncedSearch) ||
                           poem.reflection.localizedCaseInsensitiveContains(debouncedSearch)
                } else {
                    return poem.poet.localizedCaseInsensitiveContains(debouncedSearch)
                }
            }
        }

        return result
    }

    // Revealed subsets for swipe navigation
    private var revealedFilteredPoems: [Poem] {
        filteredPoems.filter { revealedPoemsStore.isRevealed($0) }
    }

    private var revealedFilteredNightingale: [Poem] {
        filteredNightingaleCouplets.filter { revealedPoemsStore.revealedNightingaleIDs.contains($0.id) }
    }

    private var revealedPoetBios: [PoetBio] {
        let allRevealed = revealedPoemsStore.getRevealedPoems() + revealedPoemsStore.getRevealedNightingaleCouplets()
        let poetNames = Set(allRevealed.map(\.poet))
        var bios = PoetBio.all.filter { poetNames.contains($0.id) }

        if let poet = selectedPoet {
            bios = bios.filter { $0.id == poet }
        }

        if !debouncedSearch.isEmpty {
            bios = bios.filter {
                $0.name.localizedCaseInsensitiveContains(debouncedSearch) ||
                $0.homeland.localizedCaseInsensitiveContains(debouncedSearch) ||
                $0.bio.localizedCaseInsensitiveContains(debouncedSearch)
            }
        }

        return bios
    }

    // Unique poets across all poems for filter chips
    private var allPoetNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for poem in PoemLibrary.poems + NightingaleCouplets.couplets {
            if seen.insert(poem.poet).inserted {
                result.append(poem.poet)
            }
        }
        return result
    }

    // Whether POTD should be visible
    private var shouldShowPOTD: Bool {
        guard !showFavoritesOnly,
              let potd = revealedPoemsStore.poemOfTheDay else { return false }
        if let poet = selectedPoet, potd.poet != poet { return false }
        return true
    }

    // MARK: - Adaptive Color Palette

    private var colors: AdaptiveColors { AdaptiveColors(colorScheme: colorScheme) }
    private var bgBase: Color { colors.bgBase }
    private var cardColor: Color { colors.cardColor }
    private var rose: Color { colors.rose }
    private var gold: Color { colors.gold }
    private var textPrimary: Color { colors.textPrimary }
    private var textSecondary: Color { colors.textSecondary }
    private var textTertiary: Color { colors.textTertiary }

    private var highlight: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.75, blue: 0.2)
            : Color(red: 0.78, green: 0.52, blue: 0.08)
    }
    private var surfaceFill: Color { textPrimary.opacity(0.06) }
    private var surfaceFillSubtle: Color { textPrimary.opacity(0.03) }
    private var trackFill: Color { textPrimary.opacity(0.08) }

    private let tileColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Poet-specific accent palette — each poet gets a unique hue
    private func poetAccent(_ poet: String) -> Color {
        switch poet {
        case "Hafez":    return Color(red: 0.95, green: 0.75, blue: 0.40)
        case "Rumi":     return Color(red: 0.30, green: 0.70, blue: 0.68)
        case "Khayyam":  return Color(red: 0.65, green: 0.50, blue: 0.80)
        case "Ferdowsi": return Color(red: 0.82, green: 0.58, blue: 0.32)
        default:         return rose
        }
    }

    private func poetInitial(_ poet: String) -> String {
        switch poet {
        case "Hafez":    return "H"
        case "Rumi":     return "R"
        case "Khayyam":  return "K"
        case "Ferdowsi": return "F"
        case "Saadi":    return "S"
        default:         return String(poet.prefix(1))
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layered warm background
            bgBase.ignoresSafeArea()

            RadialGradient(
                colors: [
                    colorScheme == .dark
                        ? Color(red: 0.18, green: 0.14, blue: 0.08).opacity(0.4)
                        : Color(red: 0.88, green: 0.82, blue: 0.72).opacity(0.3),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.1),
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            (colorScheme == .dark
                ? Color(red: 1.0, green: 0.85, blue: 0.55).opacity(0.03)
                : Color(red: 0.88, green: 0.82, blue: 0.72).opacity(0.02))
                .ignoresSafeArea()

            // Dust particles — paused when library is off-screen
            LibraryDustCanvas(reduceMotion: reduceMotion, isActive: isActive, isDark: colorScheme == .dark)

            if revealedPoemsStore.getRevealedPoems().isEmpty && revealedPoemsStore.getRevealedNightingaleCouplets().isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Poem of the Day
                        if shouldShowPOTD, let potd = revealedPoemsStore.poemOfTheDay {
                            poemOfTheDayCard(potd)
                        }

                        // Filter bar
                        filterBar

                        // Favorites empty state
                        if showFavoritesOnly && filteredPoems.isEmpty && filteredNightingaleCouplets.isEmpty {
                            favoritesEmptyState
                        }

                        // Lotus poems
                        if !filteredPoems.isEmpty {
                            sectionHeader(
                                icon: "LotusFull",
                                title: "From the Lotus",
                                subtitle: "Verses that bloomed from the pool",
                                count: revealedPoemsStore.revealedCount,
                                total: revealedPoemsStore.totalPoemsCount
                            )

                            let lotusRevealed = revealedFilteredPoems
                            let lotusIndex = Dictionary(uniqueKeysWithValues: lotusRevealed.enumerated().map { ($1.id, $0) })

                            LazyVGrid(columns: tileColumns, spacing: 12) {
                                ForEach(Array(filteredPoems.enumerated()), id: \.element.id) { _, poem in
                                    if revealedPoemsStore.isRevealed(poem) {
                                        let idx = lotusIndex[poem.id] ?? 0
                                        NavigationLink(destination: PoemDetailView(poems: lotusRevealed, currentIndex: idx)) {
                                            poemTile(poem)
                                        }
                                        .buttonStyle(.plain)
                                        .simultaneousGesture(TapGesture().onEnded { audio.playSFX(.gentleTap) })
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel("\(poem.poet). \(poem.english)")
                                        .accessibilityHint("Double tap to view full poem")
                                    } else {
                                        LockedPoemTileView(poet: poem.poet, accent: poetAccent(poem.poet))
                                    }
                                }
                            }
                        }

                        // Persian divider
                        if !filteredPoems.isEmpty && !filteredNightingaleCouplets.isEmpty {
                            persianDivider
                        }

                        // Nightingale couplets
                        if !filteredNightingaleCouplets.isEmpty {
                            sectionHeader(
                                icon: "Nightingale02",
                                title: "From the Nightingale",
                                subtitle: "Couplets gifted by the garden's songbird",
                                count: revealedPoemsStore.revealedNightingaleCount,
                                total: NightingaleCouplets.couplets.count
                            )

                            let nightRevealed = revealedFilteredNightingale
                            let nightIndex = Dictionary(uniqueKeysWithValues: nightRevealed.enumerated().map { ($1.id, $0) })

                            LazyVGrid(columns: tileColumns, spacing: 12) {
                                ForEach(Array(filteredNightingaleCouplets.enumerated()), id: \.element.id) { _, couplet in
                                    if revealedPoemsStore.revealedNightingaleIDs.contains(couplet.id) {
                                        let idx = nightIndex[couplet.id] ?? 0
                                        NavigationLink(destination: PoemDetailView(poems: nightRevealed, currentIndex: idx)) {
                                            poemTile(couplet)
                                        }
                                        .buttonStyle(.plain)
                                        .simultaneousGesture(TapGesture().onEnded { audio.playSFX(.gentleTap) })
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel("\(couplet.poet). \(couplet.english)")
                                        .accessibilityHint("Double tap to view full couplet")
                                    } else {
                                        LockedPoemTileView(poet: couplet.poet, accent: poetAccent(couplet.poet))
                                    }
                                }
                            }
                        }

                        // Persian divider
                        if !filteredNightingaleCouplets.isEmpty && !revealedPoetBios.isEmpty {
                            persianDivider
                        }

                        // Poet biographies
                        if !revealedPoetBios.isEmpty && !showFavoritesOnly {
                            poetsSectionHeader

                            ForEach(revealedPoetBios) { poet in
                                poetCard(poet)
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
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbarBackground(bgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: searchText) { newValue in
            searchDebounceTask?.cancel()
            if newValue.isEmpty {
                debouncedSearch = ""
            } else {
                searchDebounceTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                    guard !Task.isCancelled else { return }
                    debouncedSearch = newValue
                }
            }
        }
    }

    // MARK: - Poem of the Day

    private func poemOfTheDayCard(_ poem: Poem) -> some View {
        NavigationLink(destination: PoemDetailView(poem: poem)) {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(gold)
                    Text("Poem of the Day")
                        .font(.system(size: footnoteSize, weight: .semibold, design: .serif))
                        .foregroundStyle(gold)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Spacer()
                }

                Text(poem.english)
                    .font(.system(size: bodySize, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(textPrimary.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("— \(poem.poet)")
                    .font(.system(size: footnoteSize, weight: .medium, design: .serif))
                    .foregroundStyle(gold.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.25, green: 0.20, blue: 0.08).opacity(0.5),
                                   Color(red: 0.15, green: 0.12, blue: 0.05).opacity(0.3)]
                                : [Color(red: 0.82, green: 0.75, blue: 0.60).opacity(0.4),
                                   Color(red: 0.88, green: 0.83, blue: 0.72).opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .shadow(color: gold.opacity(0.12), radius: 25)
        .buttonStyle(.plain)
        .padding(.top, 4)
        .simultaneousGesture(TapGesture().onEnded { audio.playSFX(.gentleTap) })
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Poem of the Day by \(poem.poet). \(poem.english)")
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All", isSelected: selectedPoet == nil) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPoet = nil }
                    }

                    ForEach(allPoetNames, id: \.self) { poet in
                        filterChip(poet, isSelected: selectedPoet == poet, selectedColor: poetAccent(poet)) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPoet = selectedPoet == poet ? nil : poet
                            }
                        }
                    }
                }
            }

            Button {
                audio.playSFX(.gentleTap)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFavoritesOnly.toggle()
                }
            } label: {
                Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                    .font(.system(size: bodySize))
                    .foregroundStyle(showFavoritesOnly ? rose : textPrimary.opacity(0.5))
                    .frame(width: 36, height: 32)
                    .background(
                        Capsule()
                            .fill(showFavoritesOnly ? rose.opacity(0.2) : surfaceFill)
                    )
            }
            .accessibilityLabel(showFavoritesOnly ? "Show all poems" : "Show favorites only")
        }
        .padding(.top, 4)
    }

    private func filterChip(_ label: String, isSelected: Bool, selectedColor: Color? = nil, action: @escaping () -> Void) -> some View {
        let chipColor = selectedColor ?? gold
        return Button {
            audio.playSFX(.gentleTap)
            action()
        } label: {
            Text(label)
                .font(.system(size: chipSize, weight: .medium, design: .serif))
                .foregroundStyle(isSelected ? (colorScheme == .dark ? .black : .white) : textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? chipColor : surfaceFill)
                )
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Favorites Empty State

    private var favoritesEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(rose.opacity(0.4))

            Text("No favorites yet")
                .font(.system(size: bodySize, weight: .medium, design: .serif))
                .foregroundStyle(textSecondary)

            Text("Tap the heart on any poem to save it.")
                .font(.system(size: chipSize, design: .serif))
                .foregroundStyle(textTertiary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Persian Divider

    private var persianDivider: some View {
        HStack(spacing: 5) {
            gradientLine

            // Five nested diamonds: tiny-small-large-small-tiny
            diamond(size: 3, opacity: 0.15)
            diamond(size: 5, opacity: 0.25)
            diamond(size: 8, opacity: 0.40)
            diamond(size: 5, opacity: 0.25)
            diamond(size: 3, opacity: 0.15)

            gradientLine
        }
        .frame(height: 20)
        .padding(.vertical, 6)
    }

    private var gradientLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, gold.opacity(0.25), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }

    private func diamond(size: CGFloat, opacity: Double = 0.3) -> some View {
        Rectangle()
            .fill(gold.opacity(opacity))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String, subtitle: String, count: Int, total: Int) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(gold.opacity(0.08))
                            .frame(width: 40, height: 40)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(gold)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(textTertiary)
                }

                Spacer()

                Text("\(count) of \(total)")
                    .font(.caption)
                    .foregroundStyle(textPrimary.opacity(0.5))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackFill)
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

    // MARK: - Poem Tile

    /// Returns (label, snippet) when the search matched a field not visible in the tile.
    private func hiddenMatchContext(for poem: Poem) -> (label: String, snippet: String)? {
        guard !debouncedSearch.isEmpty else { return nil }

        let visibleMatch =
            poem.poet.localizedCaseInsensitiveContains(debouncedSearch) ||
            poem.english.localizedCaseInsensitiveContains(debouncedSearch) ||
            poem.persian.localizedCaseInsensitiveContains(debouncedSearch)
        if visibleMatch { return nil }

        if poem.culturalNote.localizedCaseInsensitiveContains(debouncedSearch) {
            return ("Cultural Note", snippetAround(debouncedSearch, in: poem.culturalNote))
        }
        if poem.reflection.localizedCaseInsensitiveContains(debouncedSearch) {
            return ("Reflection", snippetAround(debouncedSearch, in: poem.reflection))
        }
        return nil
    }

    /// Extracts a short window of text centered on the first match.
    private func snippetAround(_ query: String, in text: String, window: Int = 50) -> String {
        guard let range = text.range(of: query, options: .caseInsensitive) else { return text }

        let matchStart = text.distance(from: text.startIndex, to: range.lowerBound)
        let matchEnd   = text.distance(from: text.startIndex, to: range.upperBound)

        let snippetStart = max(0, matchStart - window / 2)
        let snippetEnd   = min(text.count, matchEnd + window / 2)

        let lo = text.index(text.startIndex, offsetBy: snippetStart)
        let hi = text.index(text.startIndex, offsetBy: snippetEnd)
        var snippet = String(text[lo..<hi])

        if snippetStart > 0 { snippet = "\u{2026}" + snippet }
        if snippetEnd < text.count { snippet += "\u{2026}" }
        return snippet
    }

    /// Returns a `Text` with search matches highlighted in a warm amber.
    private func highlighted(_ text: String, baseColor: Color) -> Text {
        guard !debouncedSearch.isEmpty else {
            return Text(text).foregroundColor(baseColor)
        }

        var result = Text("")
        var cursor = text.startIndex

        while cursor < text.endIndex,
              let range = text.range(of: debouncedSearch, options: .caseInsensitive,
                                     range: cursor..<text.endIndex) {
            if cursor < range.lowerBound {
                result = result + Text(text[cursor..<range.lowerBound])
                    .foregroundColor(baseColor)
            }
            result = result + Text(text[range])
                .foregroundColor(highlight)
                .bold()

            cursor = range.upperBound
        }

        if cursor < text.endIndex {
            result = result + Text(text[cursor..<text.endIndex])
                .foregroundColor(baseColor)
        }

        return result
    }

    private func poemTile(_ poem: Poem) -> some View {
        let accent = poetAccent(poem.poet)
        return VStack(spacing: 8) {
            highlighted(poem.poet, baseColor: accent.opacity(0.8))
                .font(.system(size: smallSize, weight: .semibold, design: .serif))
                .textCase(.uppercase)
                .tracking(1.5)

            highlighted(poem.english, baseColor: textPrimary)
                .font(.system(size: bodySmallSize, weight: .medium, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Circle()
                .fill(accent.opacity(0.35))
                .frame(width: 4, height: 4)

            highlighted(poem.persian, baseColor: textPrimary.opacity(0.45))
                .font(.system(size: captionSize, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Show context when match is in a non-visible field
            if let match = hiddenMatchContext(for: poem) {
                VStack(spacing: 2) {
                    Text(match.label)
                        .font(.system(size: tinySize, weight: .semibold))
                        .foregroundStyle(gold.opacity(0.5))
                        .textCase(.uppercase)

                    highlighted(match.snippet, baseColor: textTertiary)
                        .font(.system(size: smallSize, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.top, 2)
            }

            // Favorite indicator
            if revealedPoemsStore.isFavorite(poem) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(accent.opacity(0.5))
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: tileMinHeight)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.06), cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Poet monogram watermark
                Text(poetInitial(poem.poet))
                    .font(.system(size: 52, weight: .ultraLight, design: .serif))
                    .foregroundStyle(accent.opacity(0.04))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 8)
                    .padding(.bottom, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accent.opacity(0.20), lineWidth: 0.5)
            )
        )
    }

    // MARK: - Locked Poem Tile (moved to LockedPoemTileView struct below)

    // MARK: - Poets Section

    private var poetsSectionHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: headlineSize))
                    .foregroundStyle(gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Meet the Poets")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(gold)

                    Text("The voices behind the verses")
                        .font(.caption2)
                        .foregroundStyle(textTertiary)
                }

                Spacer()
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [gold.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meet the Poets: \(revealedPoetBios.count) discovered")
    }

    private func poetCard(_ poet: PoetBio) -> some View {
        let accent = poetAccent(poet.id)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    highlighted(poet.name, baseColor: accent)
                        .font(.system(size: headlineSize, weight: .semibold, design: .serif))

                    HStack(spacing: 8) {
                        Text(poet.years)
                        Text("\u{00B7}")
                        highlighted(poet.homeland, baseColor: textPrimary.opacity(0.4))
                    }
                    .font(.system(size: footnoteSize, design: .serif))
                    .foregroundStyle(textPrimary.opacity(0.4))
                }
                Spacer()
            }

            highlighted(poet.bio, baseColor: textPrimary.opacity(0.75))
                .font(.system(size: bodySmallSize, design: .serif))
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.05), cardColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.15), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(poet.name), \(poet.years), from \(poet.homeland). \(poet.bio)")
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
                    .foregroundStyle(textPrimary.opacity(0.8))

                Text("Tap the pool in your garden\nto reveal hidden verses")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textPrimary.opacity(0.4))
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No poems yet. Tap the pool in your garden to reveal hidden verses.")
    }
}

// MARK: - Locked Poem Tile (own struct for @State shimmer)

private struct LockedPoemTileView: View {
    let poet: String
    let accent: Color

    @ScaledMetric(relativeTo: .caption) private var smallSize: CGFloat = 12
    @ScaledMetric(relativeTo: .footnote) private var footnoteSize: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var tileMinHeight: CGFloat = 190
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var shimmerPhase: CGFloat = -0.5

    private var textPrimary: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.08)
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .foregroundStyle(accent.opacity(0.18))

            Text(poet)
                .font(.system(size: smallSize, weight: .semibold, design: .serif))
                .foregroundStyle(accent.opacity(0.30))
                .textCase(.uppercase)
                .tracking(1.5)

            Text("A verse awaits\u{2026}")
                .font(.system(size: footnoteSize, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(textPrimary.opacity(0.15))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: tileMinHeight)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(textPrimary.opacity(colorScheme == .dark ? 0.03 : 0.04))
                .overlay(
                    // Slow diagonal shimmer — just a gradient UV shift, no blur
                    LinearGradient(
                        colors: [.clear, accent.opacity(reduceMotion ? 0 : 0.05), .clear],
                        startPoint: UnitPoint(x: shimmerPhase - 0.4, y: shimmerPhase - 0.4),
                        endPoint: UnitPoint(x: shimmerPhase + 0.4, y: shimmerPhase + 0.4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.08), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Locked poem by \(poet). Visit the garden to reveal it.")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                shimmerPhase = 1.5
            }
        }
    }
}
