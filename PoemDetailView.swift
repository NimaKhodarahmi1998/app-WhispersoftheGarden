//
//  PoemDetailView.swift
//  WhispersoftheGardenApp
//

import SwiftUI

struct PoemDetailView: View {
    let poem: Poem

    private let bgColor = Color(red: 0.02, green: 0.08, blue: 0.18)
    private let rose = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let gold = Color(red: 1.0, green: 0.85, blue: 0.55)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Poet
                    Text(poem.poet)
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(rose.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .accessibilityLabel("Poet: \(poem.poet)")

                    // English Translation
                    VStack(spacing: 8) {
                        Text("Translation")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.35))
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(poem.english)
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .italic()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(gold)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Translation: \(poem.english)")

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
                            .foregroundStyle(.white.opacity(0.35))
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(poem.persian)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityHidden(true)

                    // Cultural Note
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Cultural Context", systemImage: "book.closed")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(gold.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(poem.culturalNote)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Cultural Context: \(poem.culturalNote)")

                    // Reflection
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Reflection", systemImage: "heart")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(rose.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(poem.reflection)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(rose.opacity(0.08))
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Reflection: \(poem.reflection)")

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Poem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
