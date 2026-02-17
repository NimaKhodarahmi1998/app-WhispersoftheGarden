//
//  GardenElementView.swift → NightingaleView
//  WhispersoftheGardenApp
//
//  Interactive nightingale that perches in the garden.
//  Shows Nightingale02 (sitting) when perched,
//  Nightingale01 (wings spread) when flying.
//

import SwiftUI

struct NightingaleView: View {

    let size: CGFloat
    let isPerched: Bool

    var body: some View {
        Image(isPerched ? "Nightingale02" : "Nightingale01")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .contentShape(Circle().scale(1.8))
            .accessibilityLabel("Nightingale")
            .accessibilityHint("Double tap to see the nightingale fly and reveal a Hafez couplet")
            .accessibilityAddTraits(.isButton)
    }
}
