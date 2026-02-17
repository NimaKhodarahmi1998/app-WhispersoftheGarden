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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var showText = false

    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let uiImage = UIImage(named: "Katibe.PNG") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, isIPad ? 40 : 20)
                }

                VStack(spacing: isIPad ? 10 : 4) {
                    Text("— \(poet)")
                        .font(.system(size: isIPad ? 22 : 16, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.persianIndigo.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text("Original")
                        .font(.system(size: isIPad ? 14 : 10, design: .serif))
                        .foregroundStyle(Color.persianIndigo.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(persian)
                        .font(.system(size: isIPad ? 30 : 21, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.persianIndigo)

                    Text("Translation")
                        .font(.system(size: isIPad ? 14 : 10, design: .serif))
                        .foregroundStyle(Color.persianIndigo.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(english)
                        .font(.system(size: isIPad ? 22 : 16, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.persianIndigo.opacity(0.8))

                    Rectangle()
                        .fill(Color.persianIndigo.opacity(0.25))
                        .frame(width: isIPad ? 80 : 40, height: 0.5)

                    Text(culturalNote)
                        .font(.system(size: isIPad ? 16 : 12, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.persianIndigo.opacity(0.75))

                    Text(reflection)
                        .font(.system(size: isIPad ? 16 : 12, weight: .medium, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.persianIndigo.opacity(0.85))
                }
                .frame(maxWidth: isIPad ? 380 : 220)
                .offset(y: -geo.size.height * 0.03)
                .padding(.bottom, isIPad ? geo.size.height * 0.04 : geo.size.height * 0.02)
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : geo.size.height * 0.01)
                .animation(.easeOut(duration: 0.5), value: showText)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Poem by \(poet). Original: \(persian). Translation: \(english). Cultural note: \(culturalNote). Reflection: \(reflection)")
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
