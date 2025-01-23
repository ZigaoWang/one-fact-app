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
    @ObservedObject private var viewModel: FactViewModel
    @State private var selectedCategory: Category?
    @State private var showingConfirmation = false
    @State private var showingFactView = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerScale: CGFloat = 1
    @State private var isRefreshing = false
    @State private var headerOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var categoriesOffset: CGFloat = 50
    @Environment(\.scenePhase) var scenePhase
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    init(viewModel: FactViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95),
                        Color(.systemBackground).opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    ScrollOffsetReader()
                    mainContent
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    headerScale = max(0.85, min(1.0, 1 - abs(value) / 500))
                }
                .refreshable {
                    await refreshContent()
                }
            }
            .overlay(loadingOverlay)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.refreshDailyStatus()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    headerOpacity = 1
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    cardOpacity = 1
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                    categoriesOffset = 0
                }
            }
        }
        .sheet(isPresented: $showingFactView) {
            if let category = selectedCategory {
                FactDetailView(category: category)
                    .environmentObject(viewModel)
            }
        }
        .alert("Ready for Today's Fact?", isPresented: $showingConfirmation) {
            Button("Let's Go!", role: .none) {
                withAnimation(.spring()) {
                    showingFactView = true
                }
            }
            Button("Maybe Later", role: .cancel) {}
        } message: {
            Text("Discover an interesting fact about \(selectedCategory?.name ?? "this topic")!")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            welcomeHeader
            dailyStatusCard
            categoriesSection
        }
        .padding(.bottom, 20)
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to")
                .font(.title2)
                .foregroundColor(.secondary)
                .offset(y: -scrollOffset * 0.2)
            Text("One Fact")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)
                .offset(y: -scrollOffset * 0.3)
                .scaleEffect(headerScale)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top)
        .opacity(headerOpacity)
    }
    
    private var dailyStatusCard: some View {
        DailyStatusCard(
            hasSeenFactToday: viewModel.hasSeenFactToday,
            category: viewModel.todaysCategory,
            showingFactView: $showingFactView,
            selectedCategory: $selectedCategory
        )
        .padding(.horizontal)
        .opacity(cardOpacity)
        .rotation3DEffect(
            .degrees(max(-10, min(0, scrollOffset * 0.1))),
            axis: (x: 1, y: 0, z: 0)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.title2.bold())
                .padding(.horizontal)
                .opacity(cardOpacity)
            
            categoriesGrid
        }
        .offset(y: categoriesOffset)
    }
    
    private var categoriesGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.categories) { category in
                CategoryCard(
                    category: category,
                    isSelected: category.name == viewModel.todaysCategory?.name,
                    isDisabled: !viewModel.canViewCategory(category),
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            handleCategoryTap(category)
                        }
                    }
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .shadow(
                    color: category.color.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingOverlay: some View {
        Group {
            if isRefreshing {
                ZStack {
                    Color(.systemBackground).opacity(0.8)
                    ProgressView()
                        .scaleEffect(1.5)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }
    
    private func handleCategoryTap(_ category: Category) {
        selectedCategory = category
        if !viewModel.hasSeenFactToday {
            showingConfirmation = true
        } else {
            showingFactView = true
        }
    }
    
    private func refreshContent() async {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = true
        }
        viewModel.refreshDailyStatus()
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = false
        }
    }
}

struct ScrollOffsetReader: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: proxy.frame(in: .named("scroll")).minY
            )
        }
        .frame(height: 0)
    }
}

struct DailyStatusCard: View {
    let hasSeenFactToday: Bool
    let category: Category?
    @Binding var showingFactView: Bool
    @Binding var selectedCategory: Category?
    
    var body: some View {
        Button {
            if hasSeenFactToday, let category = category {
                selectedCategory = category
                showingFactView = true
            }
        } label: {
            VStack(spacing: 16) {
                if hasSeenFactToday, let category = category {
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(category.icon)
                .font(.system(size: 44))
                .padding(20)
                .background(
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .overlay(
                            Circle()
                                .stroke(category.color.opacity(0.3), lineWidth: 1)
                        )
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
                .shadow(
                    color: category.color.opacity(isSelected ? 0.2 : 0.1),
                    radius: isSelected ? 5 : 10,
                    x: 0,
                    y: isSelected ? 2 : 5
                )
        )
        .opacity(isDisabled ? 0.5 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct FactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: FactViewModel
    @State private var showContent = false
    @State private var showRelatedArticles = false
    @State private var dragOffset = CGSize.zero
    @State private var cardRotation: Double = 0
    @GestureState private var dragState = DragState.inactive
    
    let category: Category
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient with parallax effect
                LinearGradient(
                    gradient: Gradient(colors: [
                        category.color.opacity(0.2),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .offset(x: -dragOffset.width * 0.1, y: -dragOffset.height * 0.1)
                .animation(.easeOut(duration: 0.2), value: dragOffset)
                
                if viewModel.isLoading {
                    LoadingView()
                        .transition(.scale.combined(with: .opacity))
                } else if let fact = viewModel.currentFact {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Floating category icon
                            Text(category.icon)
                                .font(.system(size: 60))
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .rotation3DEffect(
                                    .degrees(cardRotation),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                            
                            // Fact card with 3D effect
                            FactCard(fact: fact, category: category)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 40)
                                .rotation3DEffect(
                                    .degrees(dragState.translation.width / 20),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                                .gesture(
                                    DragGesture()
                                        .updating($dragState) { drag, state, _ in
                                            state = .dragging(translation: drag.translation)
                                        }
                                        .onEnded { value in
                                            let velocity = CGSize(
                                                width: value.predictedEndLocation.x - value.location.x,
                                                height: value.predictedEndLocation.y - value.location.y
                                            )
                                            
                                            if abs(velocity.width) > 300 {
                                                withAnimation(.spring()) {
                                                    dismiss()
                                                }
                                            } else {
                                                withAnimation(.spring()) {
                                                    dragOffset = .zero
                                                }
                                            }
                                        }
                                )
                            
                            // Related articles with staggered animation
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
                    .transition(.scale.combined(with: .opacity))
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
            // Start loading animation
            withAnimation(.easeOut(duration: 0.3)) {
                cardRotation = 360
            }
            
            try? await viewModel.fetchFactByCategory(category.name)
            
            // Staggered content reveal
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showRelatedArticles = true
            }
        }
    }
}

enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
}

struct FactCard: View {
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
