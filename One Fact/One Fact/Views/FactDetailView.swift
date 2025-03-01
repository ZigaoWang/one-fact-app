import SwiftUI

struct FactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: FactViewModel
    @State private var showContent = false
    @State private var showRelatedArticles = false
    @State private var showChat = false
    @State private var cardRotation: Double = 0
    @State private var dragState = DragState.inactive
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedTab = 0
    @Namespace private var animation
    
    let category: Category
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background
                LinearGradient(
                    gradient: Gradient(colors: [
                        category.color.opacity(0.3),
                        category.color.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .scaleEffect(1.5)
                .offset(
                    x: -dragOffset.width * 0.5,
                    y: -dragOffset.height * 0.5
                )
                .blur(radius: abs(dragOffset.height / 50))
                .animation(.easeOut(duration: 0.3), value: dragOffset)
                
                if let fact = viewModel.currentFact {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Hero section
                            VStack(spacing: 16) {
                                // Category icon with animated background
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(0.15))
                                        .frame(width: 100, height: 100)
                                        .matchedGeometryEffect(id: "background", in: animation)
                                    
                                    Image(systemName: category.icon)
                                        .font(.system(size: 48))
                                        .foregroundColor(category.color)
                                        .matchedGeometryEffect(id: "icon", in: animation)
                                }
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .rotation3DEffect(
                                    .degrees(cardRotation),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                                
                                // Category name with gradient
                                Text(category.name)
                                    .font(.title2.bold())
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                category.color,
                                                category.color.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "title", in: animation)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, geometry.safeAreaInsets.top + 16)
                            .padding(.bottom, 24)
                            
                            // Main content
                            VStack(spacing: 32) {
                                // Fact content card
                                VStack(alignment: .leading, spacing: 20) {
                                    // Date
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(category.color)
                                        Text(fact.displayDate.formatted(date: .long, time: .omitted))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Content
                                    Text(fact.content)
                                        .font(.body)
                                        .lineSpacing(8)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    // Tags
                                    if !fact.tags.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(fact.tags, id: \.self) { tag in
                                                    Text(tag)
                                                        .font(.caption.bold())
                                                        .foregroundStyle(
                                                            LinearGradient(
                                                                colors: [
                                                                    category.color,
                                                                    category.color.opacity(0.8)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(
                                                            Capsule()
                                                                .fill(category.color.opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 8)
                                    
                                    // Source with icon
                                    if let url = fact.url {
                                        Link(destination: URL(string: url)!) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "link")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(category.color)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Source")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Text(fact.source)
                                                        .font(.subheadline.bold())
                                                        .foregroundColor(.primary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(.secondarySystemBackground))
                                            )
                                        }
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(
                                            color: category.color.opacity(0.1),
                                            radius: 20,
                                            x: 0,
                                            y: 10
                                        )
                                )
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 40)
                                
                                // AI Exploration
                                VStack(alignment: .leading, spacing: 16) {
                                    // Header
                                    Text("AI Knowledge Explorer")
                                        .font(.title3.bold())
                                        .foregroundColor(.primary)
                                    
                                    Text("Dive deeper into today's fact with the help of AI. Ask questions, explore related concepts, or learn about practical applications.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                    
                                    // Chat Button
                                    Button {
                                        withAnimation {
                                            showChat = true
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                                .font(.system(size: 20))
                                            Text("Ask AI Assistant")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [category.color, category.color.opacity(0.8)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: category.color.opacity(0.3), radius: 10, x: 0, y: 5)
                                        )
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(
                                            color: category.color.opacity(0.1),
                                            radius: 20,
                                            x: 0,
                                            y: 10
                                        )
                                )
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 40)
                                
                                // Related articles
                                if !fact.relatedArticles.isEmpty {
                                    RelatedArticlesSection(articles: fact.relatedArticles, category: category)
                                        .opacity(showRelatedArticles ? 1 : 0)
                                        .offset(y: showRelatedArticles ? 0 : 60)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                    }
                    .coordinateSpace(name: "scroll")
                } else {
                    LoadingView()
                }
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding()
                    }
                    Spacer()
                }
                
                // Chat sheet
                .sheet(isPresented: $showChat) {
                    if let fact = viewModel.currentFact {
                        VStack(spacing: 0) {
                            // Custom sheet header
                            VStack(spacing: 8) {
                                HStack {
                                    Text("AI Knowledge Explorer")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showChat = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text("Ask questions about today's fact to explore deeper")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            
                            // Chat content
                            ChatView(fact: fact)
                        }
                        .background(Color(.systemBackground))
                        .edgesIgnoringSafeArea(.bottom)
                    }
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragState = .dragging(translation: value.translation)
                }
                .onEnded { value in
                    if value.predictedEndTranslation.height > 100 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragState = .inactive
                        }
                    }
                }
        )
        .offset(y: dragOffset.height)
        .task {
            // Start loading animation
            withAnimation(.easeOut(duration: 0.3)) {
                cardRotation = 360
            }
            
            // Load fact
            await viewModel.fetchFactByCategory(category.name)
            
            // Reset rotation
            withAnimation(.easeOut(duration: 0.3)) {
                cardRotation = 0
            }
            
            // Staggered content reveal
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showRelatedArticles = true
            }
        }
    }
    
    private var dragOffset: CGSize {
        switch dragState {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
}

enum DragState {
    case inactive
    case dragging(translation: CGSize)
}

#Preview {
    FactDetailView(category: Category(name: "Science", icon: "🔬", color: .blue))
        .environmentObject(FactViewModel())
}
