//
//  OptionsView.swift
//  WhispersoftheGardenApp
//
//  Audio settings: music toggle, volume control.
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @ObservedObject private var audio = GardenAudioEngine.shared

    @ScaledMetric(relativeTo: .body) private var settingLabelSize: CGFloat = 17

    private let gold = Color(red: 1.0, green: 0.92, blue: 0.65)
    private let darkGold = Color(red: 0.92, green: 0.78, blue: 0.48)
    private let deepBlue = Color(red: 0.03, green: 0.08, blue: 0.18)
    private let navyBg = Color(red: 0/255, green: 32/255, blue: 72/255)

    var body: some View {
        ZStack {
            navyBg
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Options")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(gold)

                VStack(spacing: 0) {
                    // Music toggle
                    settingRow(
                        icon: "music.note",
                        label: "Music",
                        accessibilityLabel: "Ambient Music"
                    ) {
                        Toggle("", isOn: $audio.isMusicEnabled)
                            .labelsHidden()
                            .tint(darkGold)
                            .accessibilityLabel("Ambient Music")
                    }

                    // Volume slider (visible when music enabled)
                    if audio.isMusicEnabled {
                        Divider()
                            .background(gold.opacity(0.2))

                        settingRow(
                            icon: "speaker.wave.1.fill",
                            label: "Volume",
                            accessibilityLabel: "Music Volume"
                        ) {
                            Slider(value: $audio.musicVolume, in: 0...1)
                                .tint(darkGold)
                                .frame(width: 140)
                                .accessibilityLabel("Music Volume")
                                .accessibilityValue("\(Int(audio.musicVolume * 100)) percent")
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(deepBlue.opacity(0.6))
                )
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    showOptions = false
                } label: {
                    Text("Back to Menu")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0.9, green: 0.4, blue: 0.5))
                        )
                }
                .accessibilityLabel("Back to Menu")
                .accessibilityHint("Double tap to return to the landing page")
                .padding(.bottom, 40)
            }
        }
    }

    private func settingRow<Content: View>(
        icon: String,
        label: String,
        accessibilityLabel: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(darkGold)
                .frame(width: 28)

            Text(label)
                .font(.system(size: settingLabelSize, weight: .medium, design: .serif))
                .foregroundColor(gold)

            Spacer()

            control()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
