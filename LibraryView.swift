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
    @State private var searchText = ""
    @State private var selectedPoet: String? = nil
    @State private var showFavoritesOnly = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Dynamic Type scaled font sizes
    @ScaledMetric(relativeTo: .caption2) private var tinySize: CGFloat = 9
    @ScaledMetric(relativeTo: .caption) private var smallSize: CGFloat = 10
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 11
    @ScaledMetric(relativeTo: .footnote) private var footnoteSize: CGFloat = 12
    @ScaledMetric(relativeTo: .footnote) private var chipSize: CGFloat = 13
    @ScaledMetric(relativeTo: .subheadline) private var bodySmallSize: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 16
    @ScaledMetric(relativeTo: .headline) private var headlineSize: CGFloat = 18

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

        if !searchText.isEmpty {
            result = result.filter { poem in
                if revealedPoemsStore.isRevealed(poem) {
                    return poem.poet.localizedCaseInsensitiveContains(searchText) ||
                           poem.persian.localizedCaseInsensitiveContains(searchText) ||
                           poem.english.localizedCaseInsensitiveContains(searchText) ||
                           poem.culturalNote.localizedCaseInsensitiveContains(searchText) ||
                           poem.reflection.localizedCaseInsensitiveContains(searchText)
                } else {
                    // Locked: only match poet name
                    return poem.poet.localizedCaseInsensitiveContains(searchText)
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

        if !searchText.isEmpty {
            result = result.filter { poem in
                if revealedPoemsStore.revealedNightingaleIDs.contains(poem.id) {
                    return poem.poet.localizedCaseInsensitiveContains(searchText) ||
                           poem.persian.localizedCaseInsensitiveContains(searchText) ||
                           poem.english.localizedCaseInsensitiveContains(searchText) ||
                           poem.culturalNote.localizedCaseInsensitiveContains(searchText) ||
                           poem.reflection.localizedCaseInsensitiveContains(searchText)
                } else {
                    return poem.poet.localizedCaseInsensitiveContains(searchText)
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

        if !searchText.isEmpty {
            bios = bios.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.homeland.localizedCaseInsensitiveContains(searchText) ||
                $0.bio.localizedCaseInsensitiveContains(searchText)
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

    // App palette
    private let bgBase = Color(red: 0.04, green: 0.06, blue: 0.14)
    private let cardColor = Color(red: 0.95, green: 0.88, blue: 0.7).opacity(0.06)
    private let rose = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let gold = Color(red: 1.0, green: 0.85, blue: 0.55)
    private let highlight = Color(red: 1.0, green: 0.75, blue: 0.2)

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
                colors: [Color(red: 0.18, green: 0.14, blue: 0.08).opacity(0.4), .clear],
                center: .init(x: 0.5, y: 0.1),
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            Color(red: 1.0, green: 0.85, blue: 0.55).opacity(0.03)
                .ignoresSafeArea()

            // Dust particles — paused when library is off-screen
            LibraryDustCanvas(reduceMotion: reduceMotion, isActive: isActive)

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

                            LazyVGrid(columns: tileColumns, spacing: 12) {
                                ForEach(Array(filteredPoems.enumerated()), id: \.element.id) { _, poem in
                                    if revealedPoemsStore.isRevealed(poem) {
                                        let revealedList = revealedFilteredPoems
                                        let idx = revealedList.firstIndex(where: { $0.id == poem.id }) ?? 0
                                        NavigationLink(destination: PoemDetailView(poems: revealedList, currentIndex: idx)) {
                                            poemTile(poem)
                                        }
                                        .buttonStyle(.plain)
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

                            LazyVGrid(columns: tileColumns, spacing: 12) {
                                ForEach(Array(filteredNightingaleCouplets.enumerated()), id: \.element.id) { _, couplet in
                                    if revealedPoemsStore.revealedNightingaleIDs.contains(couplet.id) {
                                        let revealedList = revealedFilteredNightingale
                                        let idx = revealedList.firstIndex(where: { $0.id == couplet.id }) ?? 0
                                        NavigationLink(destination: PoemDetailView(poems: revealedList, currentIndex: idx)) {
                                            poemTile(couplet)
                                        }
                                        .buttonStyle(.plain)
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(bgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                    .foregroundStyle(.white.opacity(0.9))
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
                            colors: [
                                Color(red: 0.25, green: 0.20, blue: 0.08).opacity(0.5),
                                Color(red: 0.15, green: 0.12, blue: 0.05).opacity(0.3)
                            ],
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFavoritesOnly.toggle()
                }
            } label: {
                Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                    .font(.system(size: bodySize))
                    .foregroundStyle(showFavoritesOnly ? rose : .white.opacity(0.5))
                    .frame(width: 36, height: 32)
                    .background(
                        Capsule()
                            .fill(showFavoritesOnly ? rose.opacity(0.2) : Color.white.opacity(0.06))
                    )
            }
            .accessibilityLabel(showFavoritesOnly ? "Show all poems" : "Show favorites only")
        }
        .padding(.top, 4)
    }

    private func filterChip(_ label: String, isSelected: Bool, selectedColor: Color? = nil, action: @escaping () -> Void) -> some View {
        let chipColor = selectedColor ?? gold
        return Button(action: action) {
            Text(label)
                .font(.system(size: chipSize, weight: .medium, design: .serif))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? chipColor : Color.white.opacity(0.06))
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
                .foregroundStyle(.white.opacity(0.6))

            Text("Tap the heart on any poem to save it.")
                .font(.system(size: chipSize, design: .serif))
                .foregroundStyle(.white.opacity(0.35))
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

    // MARK: - Poem Tile

    /// Returns (label, snippet) when the search matched a field not visible in the tile.
    private func hiddenMatchContext(for poem: Poem) -> (label: String, snippet: String)? {
        guard !searchText.isEmpty else { return nil }

        let visibleMatch =
            poem.poet.localizedCaseInsensitiveContains(searchText) ||
            poem.english.localizedCaseInsensitiveContains(searchText) ||
            poem.persian.localizedCaseInsensitiveContains(searchText)
        if visibleMatch { return nil }

        if poem.culturalNote.localizedCaseInsensitiveContains(searchText) {
            return ("Cultural Note", snippetAround(searchText, in: poem.culturalNote))
        }
        if poem.reflection.localizedCaseInsensitiveContains(searchText) {
            return ("Reflection", snippetAround(searchText, in: poem.reflection))
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
        guard !searchText.isEmpty else {
            return Text(text).foregroundColor(baseColor)
        }

        var result = Text("")
        var cursor = text.startIndex

        while cursor < text.endIndex,
              let range = text.range(of: searchText, options: .caseInsensitive,
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

            highlighted(poem.english, baseColor: .white)
                .font(.system(size: bodySmallSize, weight: .medium, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Circle()
                .fill(accent.opacity(0.35))
                .frame(width: 4, height: 4)

            highlighted(poem.persian, baseColor: .white.opacity(0.45))
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

                    highlighted(match.snippet, baseColor: .white.opacity(0.35))
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
        .frame(maxWidth: .infinity)
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
                        .foregroundStyle(.white.opacity(0.35))
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
                        highlighted(poet.homeland, baseColor: .white.opacity(0.4))
                    }
                    .font(.system(size: footnoteSize, design: .serif))
                    .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            }

            highlighted(poet.bio, baseColor: .white.opacity(0.75))
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

// MARK: - Locked Poem Tile (own struct for @State shimmer)

private struct LockedPoemTileView: View {
    let poet: String
    let accent: Color

    @ScaledMetric(relativeTo: .caption) private var smallSize: CGFloat = 10
    @ScaledMetric(relativeTo: .footnote) private var footnoteSize: CGFloat = 12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shimmerPhase: CGFloat = -0.5

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
                .foregroundStyle(.white.opacity(0.15))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
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
