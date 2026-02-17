//
//  OptionsView.swift - PLACEHOLDER
//  WhispersoftheGardenApp
//
//  Put your settings/options here
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    
    var body: some View {
        ZStack {
            Color(red: 0/255, green: 32/255, blue: 72/255)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Options")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // ✅ Add your settings here:
                // - Sound on/off
                // - Music volume
                // - Reset progress
                // - Credits
                // etc.
                
                Text("Settings coming soon...")
                    .foregroundColor(.white.opacity(0.7))
                
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
}
