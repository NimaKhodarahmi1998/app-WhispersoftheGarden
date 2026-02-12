//
//  PoemOverlayView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//

import SwiftUI

struct PoemOverlayView: View {
    let persian: String
    let english: String
    let culturalNote: String
    let reflection: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack{
            if let uiImage = UIImage(named: "Katibe.PNG") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
            
            VStack(spacing: 20) {
                Text(persian)
                    .font(.system(size: 24, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.persianIndigo)
                
                Text(english)
                    .font(.system(size: 16))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.persianIndigo.opacity(0.7))
                
                Divider()
                   // .padding(.vertical, 2)
                
                Text(culturalNote)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.persianIndigo.opacity(0.75))
                
                Text(reflection)
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.persianIndigo)
                    .padding(.top, 4)
            }
            .padding(28)
            
            .padding(.horizontal, 24)
            .transition(
                reduceMotion
                ? .opacity
                : .opacity.combined(with: .scale(scale: 0.50))
            )
        }.border(.red)
    }
}
