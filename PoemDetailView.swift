//
//  PoemDetailView.swift
//  WhispersoftheGardenApp
//
//  Displays a single poem with its Persian text, English translation,
//  cultural note, and personal reflection.
//

import SwiftUI

struct PoemDetailView: View {
    
    let poem: Poem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Persian Text
                VStack(alignment: .center, spacing: 8) {
                    Text(poem.persian)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // English Translation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translation")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(poem.english)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .italic()
                }
                
                // Cultural Note
                VStack(alignment: .leading, spacing: 8) {
                    Label("Cultural Context", systemImage: "book.closed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(poem.culturalNote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // Personal Reflection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Reflection", systemImage: "heart")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(poem.reflection)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Spacer(minLength: 32)
            }
            .padding()
        }
        .navigationTitle("Poem")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PoemDetailView(
            poem: Poem(
                id: UUID(),
                persian: "بنی آدم اعضای یکدیگرند",
                english: "Human beings are members of a whole.",
                culturalNote: "Saʿdi emphasizes shared humanity as the foundation of ethics.",
                reflection: "Gentleness toward yourself is a form of care for others."
            )
        )
    }
}
