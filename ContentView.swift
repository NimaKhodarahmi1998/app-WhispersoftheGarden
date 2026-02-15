//
//  ContentView.swift
//  WhispersoftheGardenApp
//
//  Entry point that shows LandingPage first, then navigates to main app
//

import SwiftUI

struct ContentView: View {
    @StateObject private var revealedPoemsStore = RevealedPoemsStore()
    
    var body: some View {
        LandingPage()
            .environmentObject(revealedPoemsStore)
    }
}

#Preview {
    ContentView()
}
