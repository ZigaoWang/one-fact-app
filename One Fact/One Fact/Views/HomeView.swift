//
//  HomeView.swift
//  One Fact
//
//  Created by Zigao Wang on 1/21/25.
//

import SwiftUI

@MainActor
struct AsyncHomeView: View {
    @StateObject private var viewModel = FactViewModel()
    
    var body: some View {
        HomeView(viewModel: viewModel)
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: FactViewModel
    @State private var selectedCategory: Category?
    @State private var showingConfirmation = false
    @State private var showingFactView = false
    @Environment(\.scenePhase) var scenePhase
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily Status Card
                    DailyStatusCard(hasSeenFactToday: viewModel.hasSeenFactToday, category: viewModel.todaysCategory)
                    
                    // Categories Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.categories) { category in
                            CategoryCard(
                                category: category,
                                isSelected: category.name == viewModel.todaysCategory?.name
                            )
                            .onTapGesture {
                                handleCategoryTap(category)
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.checkDailyFactStatus()
            }
        }
    }
    
    private func handleCategoryTap(_ category: Category) {
        if viewModel.canViewCategory(category) {
            selectedCategory = category
            if !viewModel.hasSeenFactToday {
                showingConfirmation = true
            } else {
                showingFactView = true
            }
        }
    }
}

struct DailyStatusCard: View {
    let hasSeenFactToday: Bool
    let category: Category?
    
    var body: some View {
        VStack(spacing: 12) {
            if hasSeenFactToday, let category = category {
                VStack(spacing: 8) {
                    Text(category.icon)
                        .font(.system(size: 44))
                    
                    Text("You've learned about \(category.name) today!")
                        .font(.headline)
                        .foregroundColor(category.color)
                    
                    Text("Tap the \(category.name) card to view it again")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Ready to learn something new?")
                    .font(.headline)
                
                Text("Choose a category below")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: (category?.color ?? .black).opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text(category.icon)
                .font(.system(size: 44))
                .rotationEffect(.degrees(isPressed ? 8 : 0))
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(category.color)
            
            if isSelected {
                Text("View again")
                    .font(.caption)
                    .foregroundColor(category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(category.color.opacity(0.1))
                    )
            } else {
                Text("Tap to explore")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: category.color.opacity(0.2), radius: 10)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                category.color.opacity(isSelected ? 0.2 : 0.1),
                                Color(.systemBackground).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(category.color.opacity(isSelected ? 0.4 : 0.2), lineWidth: isSelected ? 2 : 1)
        )
        .pressAnimation(isPressed: isPressed)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct FactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: FactViewModel
    @State private var showContent = false
    @State private var showRelatedArticles = false
    
    let category: Category
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        category.color.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else if let fact = viewModel.currentFact {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Category icon
                            Text(category.icon)
                                .font(.system(size: 60))
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                            
                            // Fact card
                            FactCard(fact: fact)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 40)
                            
                            // Related articles
                            if !fact.relatedArticles.isEmpty {
                                RelatedArticlesCard(articles: fact.relatedArticles)
                                    .opacity(showRelatedArticles ? 1 : 0)
                                    .offset(y: showRelatedArticles ? 0 : 60)
                            }
                        }
                        .padding()
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            try? await viewModel.fetchFactByCategory(category.name)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            try? await viewModel.fetchFactByCategory(category.name)
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showRelatedArticles = true
            }
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
        AsyncHomeView()
    }
}
