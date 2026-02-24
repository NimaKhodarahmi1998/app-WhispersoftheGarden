//
//  OptionsView.swift
//  WhispersoftheGardenApp
//
//  Settings page — matches Library's visual language.
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @ObservedObject private var audio = GardenAudioEngine.shared
    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric(relativeTo: .body) private var labelSize: CGFloat = 17
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 13
    @ScaledMetric(relativeTo: .headline) private var headlineSize: CGFloat = 20
    @ScaledMetric(relativeTo: .largeTitle) private var pageTitleSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 15
    @ScaledMetric(relativeTo: .body) private var rowIconSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var backIconSize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption2) private var creditLabelSize: CGFloat = 10

    // MARK: - Adaptive Colors

    private var colors: AdaptiveColors { AdaptiveColors(colorScheme: colorScheme) }
    private var bgBase: Color { colors.bgBase }
    private var cardColor: Color { colors.cardColor }
    private var gold: Color { colors.gold }
    private var darkGold: Color { colors.darkGold }
    private var textPrimary: Color { colors.textPrimary }
    private var textTertiary: Color { colors.textTertiary }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layered warm background (same as Library)
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

            ScrollView {
                VStack(spacing: 24) {
                    // Header: back button + title
                    HStack(alignment: .center) {
                        homeButton

                        Text("Options")
                            .font(.system(size: pageTitleSize, weight: .bold, design: .serif))
                            .foregroundStyle(gold)

                        Spacer()
                    }
                    .padding(.top, 12)

                    // Audio section
                    audioSection

                    // Persian divider
                    persianDivider

                    // Garden progress section
                    gardenProgressSection

                    // Persian divider
                    persianDivider

                    // About the art
                    aboutSection

                    // Persian divider
                    persianDivider

                    // Credits section
                    creditsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Audio Section

    private var audioSection: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "speaker.wave.2.fill", title: "Audio", subtitle: "Music and sound effects")

            VStack(spacing: 0) {
                settingRow(icon: "music.note", label: "Music", accessibilityLabel: "Ambient Music") {
                    Toggle("", isOn: $audio.isMusicEnabled)
                        .labelsHidden()
                        .tint(darkGold)
                        .accessibilityLabel("Ambient Music")
                }

                if audio.isMusicEnabled {
                    cardDivider

                    settingRow(icon: "speaker.wave.1.fill", label: "Music Volume", accessibilityLabel: "Music Volume") {
                        Slider(value: $audio.musicVolume, in: 0...1)
                            .tint(darkGold)
                            .frame(width: 140)
                            .accessibilityLabel("Music Volume")
                            .accessibilityValue("\(Int(audio.musicVolume * 100)) percent")
                    }
                }

                cardDivider

                settingRow(icon: "waveform", label: "Sounds", accessibilityLabel: "Sound Effects") {
                    Toggle("", isOn: $audio.isSFXEnabled)
                        .labelsHidden()
                        .tint(darkGold)
                        .accessibilityLabel("Sound Effects")
                }

                if audio.isSFXEnabled {
                    cardDivider

                    settingRow(icon: "speaker.wave.1.fill", label: "Sounds Volume", accessibilityLabel: "Sounds Volume") {
                        Slider(value: $audio.sfxVolume, in: 0...1)
                            .tint(darkGold)
                            .frame(width: 140)
                            .accessibilityLabel("Sounds Volume")
                            .accessibilityValue("\(Int(audio.sfxVolume * 100)) percent")
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.05), cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
    }

    // MARK: - Garden Progress Section

    private var gardenProgressSection: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "leaf.fill", title: "Garden", subtitle: "Progress and details")

            VStack(spacing: 0) {
                infoRow(
                    icon: "book.fill",
                    label: "Poems Revealed",
                    value: "\(revealedPoemsStore.revealedCount) of \(revealedPoemsStore.totalPoemsCount)"
                )

                cardDivider

                infoRow(
                    icon: "bird.fill",
                    label: "Nightingale Verses",
                    value: "\(revealedPoemsStore.revealedNightingaleCount) of \(NightingaleCouplets.couplets.count)"
                )

                cardDivider

                infoRow(
                    icon: "heart.fill",
                    label: "Favorites",
                    value: "\(revealedPoemsStore.favoritesCount)"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.05), cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "text.book.closed.fill", title: "About", subtitle: "The art within the garden")

            VStack(spacing: 0) {
                aboutParagraph(
                    icon: "music.note.list",
                    title: "The Santur",
                    body: "The santur is a 72-string instrument you strike with small wooden hammers. I grew up hearing it at family gatherings and it always felt like it belonged in a garden somehow. Nothing here is recorded. I wrote the synthesis from scratch so every note is generated live. You can drag your finger across the pool to play it too."
                )

                cardDivider

                aboutParagraph(
                    icon: "waveform.path",
                    title: "Dastgah-e Shur",
                    body: "Shur is one of the main melodic systems in Persian music. The tuning isn\u{2019}t like Western scales. I spent a lot of time reading Hormoz Farhat\u{2019}s research to get the microtonal intervals right, because without them it just sounds wrong. The melody moves through seven gushehs, which are like emotional chapters. It never plays the same way twice."
                )

                cardDivider

                aboutParagraph(
                    icon: "sparkles",
                    title: "The Garden",
                    body: "Touch the water to place a lily pad. Tap the lily pad and it blooms into a lotus. Each lotus holds a verse from Hafez, Rumi, Saadi, Khayyam, or Ferdowsi. The more poems you find, the more alive the garden becomes. The water gets warmer, new particles appear, the light changes. I wanted it to feel like the garden remembers you."
                )

                cardDivider

                aboutParagraph(
                    icon: "bird",
                    title: "The Nightingale",
                    body: "In Persian poetry the nightingale is always in love with the rose. It keeps singing even though the rose never answers. I think that\u{2019}s beautiful. In the app, the nightingale shows up when it feels like you\u{2019}ve been patient with the garden. It brings its own verses."
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.05), cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
    }

    private func aboutParagraph(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(darkGold)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: labelSize, weight: .semibold, design: .serif))
                    .foregroundStyle(gold)
            }

            Text(body)
                .font(.system(size: captionSize, weight: .regular, design: .serif))
                .foregroundStyle(textPrimary.opacity(0.7))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "star.fill", title: "Credits", subtitle: "The people behind the garden")

            VStack(spacing: 0) {
                // Creator
                creditGroup(title: "Created by") {
                    creditLine("Nima Khodarahmi")
                    creditLine("Iran / Italy", subtle: true)
                }

                cardDivider

                // Poetry
                creditGroup(title: "Poetry") {
                    creditLine("Hafez \u{2022} Divan-e Hafez")
                    creditLine("Saadi \u{2022} Golestan & Bustan")
                    creditLine("Rumi")
                    creditLine("Omar Khayyam")
                    creditLine("Ferdowsi \u{2022} Shahnameh")
                }

                cardDivider

                // Music
                creditGroup(title: "Music") {
                    creditLine("Santur synthesis in Dastgah-e Shur")
                    creditLine("Tuning based on research by")
                    creditLine("Hormoz Farhat & Mohammad Shafiei", subtle: true)
                }

                cardDivider

                // Illustrations
                creditGroup(title: "Illustrations") {
                    creditLine("Hand-drawn in Procreate")
                    creditLine("Lily pads, lotuses, nightingale, backgrounds", subtle: true)
                    creditLine("Painted in traditional Persian colors", subtle: true)
                }

                cardDivider

                // Tools
                creditGroup(title: "Built with") {
                    creditLine("Swift \u{2022} SwiftUI \u{2022} Metal")
                    creditLine("AVFoundation \u{2022} Swift Playgrounds")
                    creditLine("Claude")
                }

                cardDivider

                // Dedication
                VStack(spacing: 6) {
                    Text("Dedicated to all the fallen")
                    Text("for the liberation of Iran")
                }
                .font(.system(size: captionSize, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(gold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.05), cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
    }

    // MARK: - Credit Helpers

    private func creditGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: creditLabelSize, weight: .semibold, design: .serif))
                .tracking(1.2)
                .foregroundStyle(darkGold)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func creditLine(_ text: String, subtle: Bool = false) -> some View {
        Text(text)
            .font(.system(size: captionSize, weight: subtle ? .regular : .medium, design: .serif))
            .foregroundStyle(subtle ? textPrimary.opacity(0.5) : textPrimary.opacity(0.75))
    }

    // MARK: - Home Button

    private var homeButton: some View {
        Button {
            audio.playSFX(.gentleTap)
            showOptions = false
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: backIconSize, weight: .semibold))
                .foregroundStyle(gold)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(cardColor)
                        .overlay(
                            Circle()
                                .stroke(gold.opacity(0.25), lineWidth: 0.5)
                        )
                )
        }
        .accessibilityLabel("Back to Home")
        .accessibilityHint("Double tap to return to the home screen")
    }

    // MARK: - Section Header (mirrors LibraryView)

    private func sectionHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: headlineSize))
                .foregroundStyle(gold)

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
        }
        .padding(.top, 4)
    }

    // MARK: - Setting Row

    private func settingRow<Content: View>(
        icon: String,
        label: String,
        accessibilityLabel: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: rowIconSize))
                .foregroundStyle(darkGold)
                .frame(width: 26)

            Text(label)
                .font(.system(size: labelSize, weight: .medium, design: .serif))
                .foregroundStyle(textPrimary)

            Spacer()

            control()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Info Row

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: rowIconSize))
                .foregroundStyle(darkGold)
                .frame(width: 26)

            Text(label)
                .font(.system(size: labelSize, weight: .medium, design: .serif))
                .foregroundStyle(textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: captionSize, weight: .medium, design: .serif))
                .foregroundStyle(textPrimary.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Shared Elements

    private var cardDivider: some View {
        Rectangle()
            .fill(gold.opacity(0.12))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }

    private var persianDivider: some View {
        HStack(spacing: 5) {
            gradientLine
            diamond(size: 3, opacity: 0.15)
            diamond(size: 5, opacity: 0.25)
            diamond(size: 8, opacity: 0.40)
            diamond(size: 5, opacity: 0.25)
            diamond(size: 3, opacity: 0.15)
            gradientLine
        }
        .frame(height: 20)
        .padding(.vertical, 2)
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

    private func diamond(size: CGFloat, opacity: Double) -> some View {
        Rectangle()
            .fill(gold.opacity(opacity))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
    }
}
