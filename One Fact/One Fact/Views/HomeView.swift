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
    @State private var showingFactView = false
    @State private var showingChatView = false
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let fact = viewModel.currentFact {
                        // Today's Fact Card
                        FactCardView(fact: fact)
                            .onTapGesture {
                                showingFactView = true
                            }
                        
                        // Related Articles
                        if !viewModel.relatedArticles.isEmpty {
                            RelatedArticlesView(articles: viewModel.relatedArticles)
                        }
                        
                        // Chat Button
                        Button(action: { showingChatView = true }) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Ask AI About This Fact")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    } else {
                        if viewModel.isLoading {
                            ProgressView("Loading today's fact...")
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.yellow)
                                Text("Welcome to One Fact!")
                                    .font(.title)
                                Text("Your daily dose of knowledge awaits.")
                                    .foregroundColor(.secondary)
                                Button("Get Today's Fact") {
                                    Task {
                                        await viewModel.fetchDailyFact()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("One Fact")
            .sheet(isPresented: $showingFactView) {
                FactDetailView(fact: viewModel.currentFact!)
            }
            .sheet(isPresented: $showingChatView) {
                ChatView(viewModel: viewModel)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.checkDailyFactStatus()
                }
            }
        }
    }
}

struct FactCardView: View {
    let fact: Fact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fact.content)
                .font(.body)
                .padding()
            
            HStack {
                Text("Source: \(fact.source)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let url = fact.url {
                    Link("Learn More", destination: URL(string: url)!)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct RelatedArticlesView: View {
    let articles: [RelatedArticle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Articles")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(articles) { article in
                        ArticleCard(article: article)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ArticleCard: View {
    let article: RelatedArticle
    
    var body: some View {
        Link(destination: URL(string: article.url)!) {
            VStack(alignment: .leading, spacing: 8) {
                if let imageUrl = article.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 200, height: 120)
                    .cornerRadius(8)
                }
                
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(width: 200, alignment: .leading)
                
                Text(article.source)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200)
        }
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: FactViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.chatMessages) { message in
                            MessageBubble(message: message.content, isUser: message.isUser)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Ask about this fact...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        let message = messageText
                        messageText = ""
                        Task {
                            await viewModel.sendChatMessage(message)
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chat with AI")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct FactDetailView: View {
    let fact: Fact
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(fact.content)
                        .font(.body)
                        .padding()
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Information")
                            .font(.headline)
                        Text("From: \(fact.source)")
                        if let url = fact.url {
                            Link("Original Article", destination: URL(string: url)!)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Today's Fact")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncHomeView()
    }
}
