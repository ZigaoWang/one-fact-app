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
                    // Welcome Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("One Fact")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Daily Status Card
                    DailyStatusCard(
                        hasSeenFactToday: viewModel.hasSeenFactToday,
                        category: viewModel.todaysCategory,
                        showingFactView: $showingFactView,
                        selectedCategory: $selectedCategory
                    )
                    .padding(.horizontal)
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        // Categories Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.categories) { category in
                                CategoryCard(
                                    category: category,
                                    isSelected: category.name == viewModel.todaysCategory?.name,
                                    isDisabled: !viewModel.canViewCategory(category),
                                    onTap: {
                                        withAnimation(.spring()) {
                                            handleCategoryTap(category)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
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
    @Binding var showingFactView: Bool
    @Binding var selectedCategory: Category?
    
    var body: some View {
        VStack(spacing: 16) {
            if hasSeenFactToday, let category = category {
                Button {
                    selectedCategory = category
                    showingFactView = true
                } label: {
                    VStack(spacing: 12) {
                        Text(category.icon)
                            .font(.system(size: 44))
                            .padding(20)
                            .background(
                                Circle()
                                    .fill(category.color.opacity(0.2))
                            )
                        
                        VStack(spacing: 4) {
                            Text("Today's Fact Category")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(category.name)
                                .font(.title2.bold())
                                .foregroundColor(category.color)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundColor(.yellow)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                        )
                    
                    VStack(spacing: 4) {
                        Text("Ready to Learn?")
                            .font(.title3.bold())
                        Text("Choose a category to discover your daily fact")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(category.icon)
                .font(.system(size: 44))
                .padding(20)
                .background(
                    Circle()
                        .fill(category.color.opacity(0.2))
                )
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(category.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: category.color.opacity(isPressed ? 0.2 : 0.1), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isDisabled ? 0.5 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            if !isDisabled {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
                onTap()
            }
        }
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
                            FactCard(fact: fact, category: category)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 40)
                            
                            // Related articles
                            if !fact.relatedArticles.isEmpty {
                                RelatedArticlesSection(articles: fact.relatedArticles, category: category)
                                    .opacity(showRelatedArticles ? 1 : 0)
                                    .offset(y: showRelatedArticles ? 0 : 60)
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

private struct FactCard: View {
    let fact: Fact
    let category: Category
    
    var body: some View {
        VStack(spacing: 20) {
            // Image Placeholder
            ZStack {
                Rectangle()
                    .fill(category.color.opacity(0.1))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(category.color.opacity(0.3))
                    Text("Fact Image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Fact Content
            VStack(alignment: .leading, spacing: 16) {
                Text(fact.content)
                    .font(.body)
                    .lineSpacing(4)
                
                HStack {
                    Text("Source: \(fact.source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let url = fact.url {
                        Link("Learn More", destination: URL(string: url)!)
                            .font(.caption.bold())
                            .foregroundColor(category.color)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: category.color.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
}

private struct RelatedArticlesSection: View {
    let articles: [RelatedArticle]
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Articles")
                .font(.headline)
                .foregroundColor(category.color)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(articles) { article in
                        RelatedArticleCard(article: article, color: category.color)
                    }
                }
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
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your fact...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Oops!")
                .font(.title2.bold())
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncHomeView()
    }
}
