//
//  PoemOverlayView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//

import SwiftUI

struct PoemOverlayView: View {
    let poet: String
    let persian: String
    let english: String
    let culturalNote: String
    let reflection: String
    var backgroundImage: String = "Katibe"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var showText = false

    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    private var isNightingale: Bool {
        backgroundImage == "Katibe2"
    }

    // Pool poems: cool indigo | Nightingale poems: warm amber-brown
    private var accentColor: Color {
        isNightingale
            ? Color(red: 0.38, green: 0.24, blue: 0.12)
            : Color.persianIndigo
    }

    private var dividerColor: Color {
        isNightingale ? Color.persianSaffron : Color.persianIndigo
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(backgroundImage)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        GeometryReader { kGeo in
                            let topInset = kGeo.size.height * (isNightingale ? 0.14 : 0.10)
                            let bottomInset = kGeo.size.height * 0.13
                            let sideInset = kGeo.size.width * 0.22
                            let innerHeight = kGeo.size.height - topInset - bottomInset

                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: isIPad ? 8 : (isNightingale ? 5 : 3)) {
                                    Spacer(minLength: 0)

                                    Text("— \(poet)")
                                        .font(.system(
                                            size: isIPad ? 20 : 14,
                                            weight: isNightingale ? .medium : .semibold,
                                            design: .serif
                                        ))
                                        .foregroundStyle(accentColor.opacity(0.7))
                                        .textCase(.uppercase)
                                        .tracking(isNightingale ? 2.0 : 1.5)

                                    Text("Translation")
                                        .font(.system(size: isIPad ? 12 : 9, design: .serif))
                                        .foregroundStyle(accentColor.opacity(0.5))
                                        .textCase(.uppercase)
                                        .tracking(1)

                                    Text(english)
                                        .font(.system(
                                            size: isIPad ? 24 : 17,
                                            weight: .medium,
                                            design: .serif
                                        ))
                                        .italic()
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(accentColor)
                                        .minimumScaleFactor(0.7)

                                    Text("Original")
                                        .font(.system(size: isIPad ? 12 : 9, design: .serif))
                                        .foregroundStyle(accentColor.opacity(0.5))
                                        .textCase(.uppercase)
                                        .tracking(1)

                                    Text(persian)
                                        .font(.system(
                                            size: isIPad ? 18 : 14,
                                            weight: .medium,
                                            design: .serif
                                        ))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(accentColor.opacity(0.8))
                                        .minimumScaleFactor(0.7)

                                    // Divider — decorative dots for nightingale, line for pool
                                    if isNightingale {
                                        Text("·  ·  ·")
                                            .font(.system(size: isIPad ? 16 : 12, weight: .light, design: .serif))
                                            .foregroundStyle(dividerColor.opacity(0.6))
                                            .padding(.vertical, isIPad ? 3 : 2)
                                    } else {
                                        Rectangle()
                                            .fill(dividerColor.opacity(0.25))
                                            .frame(width: isIPad ? 80 : 40, height: 0.5)
                                            .padding(.vertical, isIPad ? 2 : 1)
                                    }

                                    Text(culturalNote)
                                        .font(.system(size: isIPad ? 13 : 10, design: .serif))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(accentColor.opacity(0.75))

                                    // Reflection — lighter and warmer for nightingale
                                    Text(reflection)
                                        .font(.system(
                                            size: isIPad ? (isNightingale ? 15 : 14) : (isNightingale ? 12 : 11),
                                            weight: isNightingale ? .light : .medium,
                                            design: .serif
                                        ))
                                        .italic(isNightingale ? false : true)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(
                                            isNightingale
                                                ? Color(red: 0.45, green: 0.30, blue: 0.15).opacity(0.90)
                                                : Color.persianIndigo.opacity(0.85)
                                        )
                                        .padding(.top, isNightingale ? (isIPad ? 4 : 2) : 0)

                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, minHeight: innerHeight)
                            }
                            .padding(.horizontal, sideInset)
                            .padding(.top, topInset)
                            .padding(.bottom, bottomInset)
                        }
                    )
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : geo.size.height * 0.01)
                    .animation(.easeOut(duration: 0.5), value: showText)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Poem by \(poet). \(english). \(culturalNote). \(reflection)")
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .transition(
            reduceMotion
            ? .opacity
            : .opacity.combined(with: .scale(scale: 0.50))
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                showText = true
            }
        }
    }
}
