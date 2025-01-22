//
//  HomeView.swift
//  One Fact
//
//  Created by Zigao Wang on 1/21/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = FactViewModel()
    @State private var selectedCategory: Category?
    @State private var showingConfirmation = false
    @State private var showingFactView = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily Status Card
                    DailyStatusCard(hasSeenFactToday: viewModel.hasSeenFactToday)
                    
                    // Categories Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.categories) { category in
                            CategoryCard(category: category)
                                .onTapGesture {
                                    if !viewModel.hasSeenFactToday {
                                        selectedCategory = category
                                        showingConfirmation = true
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("One Fact")
            .confirmationDialog(
                "Are you ready?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Learn about \(selectedCategory?.name ?? "")") {
                    showingFactView = true
                }
                Button("Maybe later", role: .cancel) {
                    selectedCategory = nil
                }
            } message: {
                Text("You can only view one fact per day. Make it count!")
            }
            .fullScreenCover(isPresented: $showingFactView) {
                if let category = selectedCategory {
                    FactDetailView(category: category)
                        .environmentObject(viewModel)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct DailyStatusCard: View {
    let hasSeenFactToday: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasSeenFactToday ? "checkmark.circle.fill" : "sparkles")
                .font(.system(size: 40))
                .foregroundColor(hasSeenFactToday ? .green : .orange)
            
            Text(hasSeenFactToday ? "You've learned something today!" : "Ready to learn something new?")
                .font(.headline)
            
            Text(hasSeenFactToday ? "Come back tomorrow for more!" : "Choose a category below")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 12) {
            Text(category.icon)
                .font(.system(size: 44))
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(category.color)
            
            Text("Tap to explore")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: category.color.opacity(0.2), radius: 10)
        )
    }
}

struct FactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: FactViewModel
    
    let category: Category
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if let fact = viewModel.currentFact {
                    ScrollView {
                        VStack(spacing: 20) {
                            FactCard(fact: fact)
                            if !fact.relatedArticles.isEmpty {
                                RelatedArticlesCard(articles: fact.relatedArticles)
                            }
                        }
                        .padding()
                    }
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            try? await viewModel.fetchFactByCategory(category.name)
                        }
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            try? await viewModel.fetchFactByCategory(category.name)
        }
    }
}

// MARK: - Supporting Views
private struct BackgroundView: View {
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
}

private struct LoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
    }
}

private struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Try Again", action: retryAction)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

private struct FactCard: View {
    let fact: Fact
    
    var categoryIcon: String {
        switch fact.category {
        case "Science": return "🧬"
        case "History": return "📜"
        case "Technology": return "💻"
        case "Space": return "🌌"
        case "Nature": return "🌿"
        case "Art": return "🎨"
        case "Literature": return "📚"
        default: return "💡"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(categoryIcon) \(fact.category)")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Text(fact.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Text("Source: \(fact.source)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let url = fact.url {
                Link("Read More", destination: URL(string: url)!)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

private struct RelatedArticlesCard: View {
    let articles: [RelatedArticle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Articles")
                .font(.headline)
            
            ForEach(articles) { article in
                VStack(alignment: .leading, spacing: 8) {
                    if let imageUrl = article.imageUrl,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Link(destination: URL(string: article.url)!) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(article.snippet)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Source: \(article.source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
