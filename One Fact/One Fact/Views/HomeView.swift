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
            .onChange(of: scenePhase) { _ in
                if scenePhase == .active {
                    viewModel.checkDailyFactStatus()
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
                    onTap: { handleCategoryTap(category) }
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
        showingConfirmation = true
    }
    
    private func refreshContent() async {
        isRefreshing = true
        viewModel.checkDailyFactStatus()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncHomeView()
    }
}
