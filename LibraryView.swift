//
//  LibraryView.swift
//  WhispersoftheGardenApp
//
//  Displays all revealed poems in a searchable list.
//  Integrates with RevealedPoemsStore to show only unlocked poems.
//

import SwiftUI

struct LibraryView: View {
    
    @EnvironmentObject var revealedPoemsStore: RevealedPoemsStore
    @State private var searchText = ""
    
    private var revealedPoems: [Poem] {
        revealedPoemsStore.getRevealedPoems()
    }
    
    private var filteredPoems: [Poem] {
        if searchText.isEmpty {
            return revealedPoems
        }
        
        return revealedPoems.filter { poem in
            poem.persian.localizedCaseInsensitiveContains(searchText) ||
            poem.english.localizedCaseInsensitiveContains(searchText) ||
            poem.culturalNote.localizedCaseInsensitiveContains(searchText) ||
            poem.reflection.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if revealedPoems.isEmpty {
                    emptyStateView
                } else {
                    poemListView
                }
            }
            .navigationTitle("Library")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search poems..."
            )
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Poems Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Explore the garden and tap the cells to reveal poems.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Poem List
    
    private var poemListView: some View {
        List {
            Section {
                ForEach(filteredPoems) { poem in
                    NavigationLink(destination: PoemDetailView(poem: poem)) {
                        PoemRowView(poem: poem)
                    }
                }
            } header: {
                if !searchText.isEmpty {
                    Text("\(filteredPoems.count) results")
                        .textCase(.none)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(revealedPoems.count) of \(revealedPoemsStore.totalPoemsCount) poems revealed")
                        .textCase(.none)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Poem Row View

struct PoemRowView: View {
    let poem: Poem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(poem.persian)
                .font(.headline)
                .lineLimit(2)
            
            Text(poem.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .italic()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .environmentObject(RevealedPoemsStore())
}
