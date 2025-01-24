import SwiftUI

struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    
    static let allCategories: [Category] = [
        Category(name: "Technology", icon: "laptopcomputer", color: .blue),
        Category(name: "History", icon: "clock", color: .brown),
        Category(name: "General", icon: "star", color: .purple),
        Category(name: "Science", icon: "atom", color: .green),
        Category(name: "Culture", icon: "theatermasks", color: .pink),
        Category(name: "Business", icon: "chart.line.uptrend.xyaxis", color: .orange),
        Category(name: "Education", icon: "book", color: .yellow),
        Category(name: "Geography", icon: "globe", color: .cyan),
        Category(name: "Politics", icon: "building.columns", color: .red),
        Category(name: "Health", icon: "heart", color: .mint)
    ]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

import Foundation

enum CategoryEnum: String, CaseIterable {
    case technology = "Technology"
    case history = "History"
    case general = "General"
    case science = "Science"
    case culture = "Culture"
    case business = "Business"
    case education = "Education"
    case geography = "Geography"
    case politics = "Politics"
    case health = "Health"
    
    var displayName: String {
        return rawValue
    }
    
    var iconName: String {
        switch self {
        case .technology: return "laptopcomputer"
        case .history: return "clock"
        case .general: return "star"
        case .science: return "atom"
        case .culture: return "theatermasks"
        case .business: return "chart.line.uptrend.xyaxis"
        case .education: return "book"
        case .geography: return "globe"
        case .politics: return "building.columns"
        case .health: return "heart"
        }
    }
    
    var accentColor: String {
        switch self {
        case .technology: return "blue"
        case .history: return "brown"
        case .general: return "purple"
        case .science: return "green"
        case .culture: return "pink"
        case .business: return "orange"
        case .education: return "yellow"
        case .geography: return "cyan"
        case .politics: return "red"
        case .health: return "mint"
        }
    }
}
