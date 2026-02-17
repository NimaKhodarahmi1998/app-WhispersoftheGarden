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

    private var revealedPoetBios: [PoetBio] {
        let allPoems = revealedPoems + revealedNightingaleCouplets
        let poetNames = Set(allPoems.map(\.poet))
        return PoetBio.all.filter { poetNames.contains($0.id) }
    }

    // App palette
    private let bgColor = Color(red: 0.02, green: 0.08, blue: 0.18)
    private let cardColor = Color.white.opacity(0.07)
    private let rose = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let gold = Color(red: 1.0, green: 0.85, blue: 0.55)

    private let tileColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if revealedPoems.isEmpty && revealedNightingaleCouplets.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Lotus poems
                        if !filteredPoems.isEmpty {
                            sectionHeader(
                                icon: "LotusFull",
                                title: "From the Lotus",
                                subtitle: "Verses that bloomed from the pool",
                                count: revealedPoems.count,
                                total: revealedPoemsStore.totalPoemsCount
                            )

                            LazyVGrid(columns: tileColumns, spacing: 12) {
                                ForEach(filteredPoems) { poem in
                                    NavigationLink(destination: PoemDetailView(poem: poem)) {
                                        poemTile(poem, accent: rose)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("\(poem.poet). \(poem.english)")
                                    .accessibilityHint("Double tap to view full poem")
                                }
                            }
                        }

                        // Nightingale couplets
                        if !filteredNightingaleCouplets.isEmpty {
                            sectionHeader(
                                icon: "Nightingale02",
                                title: "From the Nightingale",
                                subtitle: "Couplets gifted by the garden's songbird",
                                count: revealedNightingaleCouplets.count,
                                total: NightingaleCouplets.couplets.count
                            )

                            LazyVGrid(columns: tileColumns, spacing: 12) {
                                ForEach(filteredNightingaleCouplets) { couplet in
                                    NavigationLink(destination: PoemDetailView(poem: couplet)) {
                                        poemTile(couplet, accent: rose)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("\(couplet.poet). \(couplet.english)")
                                    .accessibilityHint("Double tap to view full couplet")
                                }
                            }
                        }

                        // Poet biographies
                        if !revealedPoetBios.isEmpty {
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

    // MARK: - Poem Tile

    private func poemTile(_ poem: Poem, accent: Color) -> some View {
        VStack(spacing: 8) {
            Text(poem.poet)
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(accent.opacity(0.7))
                .textCase(.uppercase)
                .tracking(1.5)

            Text(poem.english)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)

            // Gold ornament separator
            Circle()
                .fill(gold.opacity(0.35))
                .frame(width: 4, height: 4)

            Text(poem.persian)
                .font(.system(size: 11, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Poets Section

    private var poetsSectionHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 18))
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(poet.name)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(gold)

                    HStack(spacing: 8) {
                        Text(poet.years)
                        Text("·")
                        Text(poet.homeland)
                    }
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            }

            Text(poet.bio)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(gold.opacity(0.12), lineWidth: 0.5)
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
