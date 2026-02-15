//
//  MainAppView.swift
//  WhispersoftheGardenApp
//
//  Main app with tabs for Garden and Library
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    
    var body: some View {
        TabView {
            // Garden Tab
            GardenView()
                .tabItem {
                    Label("Garden", systemImage: "leaf.fill")
                }
                .environmentObject(revealedPoemsStore)
            
            // Library Tab
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .environmentObject(revealedPoemsStore)
        }
        .accentColor(Color(red: 0.9, green: 0.4, blue: 0.5))  // Matches your app's aesthetic
    }
}

#Preview {
    MainAppView()
        .environmentObject(RevealedPoemsStore())
}
