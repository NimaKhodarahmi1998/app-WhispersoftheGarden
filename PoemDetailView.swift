//
//  PoemDetailView.swift
//  WhispersoftheGardenApp
//

import SwiftUI

struct PoemDetailView: View {
    let poems: [Poem]
    @State var currentIndex: Int
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @State private var showShareSheet = false
    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric(relativeTo: .caption) private var poetNameSize: CGFloat = 14
    @ScaledMetric(relativeTo: .title2) private var translationSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var persianSize: CGFloat = 16

    private var poem: Poem { poems[currentIndex] }

    // MARK: - Adaptive Color Palette

    private var bgColor: Color {
        colorScheme == .dark
            ? Color(red: 0.02, green: 0.08, blue: 0.18)
            : Color(red: 0.96, green: 0.93, blue: 0.87)
    }
    private var rose: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.4, blue: 0.5)
            : Color(red: 0.75, green: 0.28, blue: 0.38)
    }
    private var gold: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.85, blue: 0.55)
            : Color(red: 0.72, green: 0.56, blue: 0.18)
    }
    private var textPrimary: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.08)
    }

    /// Convenience init for single poem
    init(poem: Poem) {
        self.poems = [poem]
        self._currentIndex = State(initialValue: 0)
    }

    init(poems: [Poem], currentIndex: Int) {
        self.poems = poems
        self._currentIndex = State(initialValue: currentIndex)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if poems.count > 1 {
                TabView(selection: $currentIndex) {
                    ForEach(Array(poems.enumerated()), id: \.element.id) { index, p in
                        poemContent(p)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                poemContent(poem)
            }

            // Custom dot indicator
            if poems.count > 1 {
                VStack {
                    Spacer()
                    dotIndicator
                        .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("Poem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    revealedPoemsStore.toggleFavorite(poem)
                } label: {
                    Image(systemName: revealedPoemsStore.isFavorite(poem) ? "heart.fill" : "heart")
                        .foregroundStyle(revealedPoemsStore.isFavorite(poem) ? rose : textPrimary.opacity(0.7))
                }
                .accessibilityLabel(revealedPoemsStore.isFavorite(poem) ? "Remove from favorites" : "Add to favorites")

                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(textPrimary.opacity(0.7))
                }
                .accessibilityLabel("Share poem")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareText)
        }
    }

    // MARK: - Poem Content

    private func poemContent(_ p: Poem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Poet
                Text(p.poet)
                    .font(.system(size: poetNameSize, weight: .semibold, design: .serif))
                    .foregroundStyle(rose.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .accessibilityLabel("Poet: \(p.poet)")

                // English Translation
                VStack(spacing: 8) {
                    Text("Translation")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(textPrimary.opacity(0.35))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(p.english)
                        .font(.system(size: translationSize, weight: .medium, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(gold)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Translation: \(p.english)")

                // Divider
                Rectangle()
                    .fill(rose.opacity(0.2))
                    .frame(height: 0.5)
                    .padding(.horizontal, 40)

                // Original Persian
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(textPrimary.opacity(0.35))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(p.persian)
                        .font(.system(size: persianSize, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(textPrimary.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Original Persian: \(p.persian)")

                // Cultural Note
                VStack(alignment: .leading, spacing: 8) {
                    Label("Cultural Context", systemImage: "book.closed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(gold.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(p.culturalNote)
                        .font(.subheadline)
                        .foregroundStyle(textPrimary.opacity(0.7))
                        .lineSpacing(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(textPrimary.opacity(0.05))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Cultural Context: \(p.culturalNote)")

                // Reflection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Reflection", systemImage: "heart")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(rose.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(p.reflection)
                        .font(.subheadline)
                        .foregroundStyle(textPrimary.opacity(0.7))
                        .lineSpacing(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(rose.opacity(0.08))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Reflection: \(p.reflection)")

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Dot Indicator

    private var dotIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<poems.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? gold : textPrimary.opacity(0.2))
                    .frame(width: index == currentIndex ? 7 : 5,
                           height: index == currentIndex ? 7 : 5)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }

    // MARK: - Share

    private var shareText: String {
        "\"\(poem.english)\"\n\n\(poem.persian)\n\n\u{2014} \(poem.poet)\n\nShared from Whispers of the Garden"
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
