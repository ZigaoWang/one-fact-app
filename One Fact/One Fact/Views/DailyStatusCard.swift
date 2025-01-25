import SwiftUI

struct DailyStatusCard: View {
    let hasSeenFactToday: Bool
    let category: Category?
    @Binding var showingFactView: Bool
    @Binding var selectedCategory: Category?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(hasSeenFactToday ? "Today's Category" : "Start Your Day")
                    .font(.title3.bold())
                
                Spacer()
                
                if hasSeenFactToday, let category = category {
                    Text(category.icon)
                        .font(.title2)
                }
            }
            
            if hasSeenFactToday, let category = category {
                Text("You're exploring \(category.name) today!")
                    .foregroundColor(.secondary)
                
                Button {
                    selectedCategory = category
                    showingFactView = true
                } label: {
                    Text("Continue Reading")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(category.color)
                        .cornerRadius(12)
                }
            } else {
                Text("Choose a category to discover an interesting fact!")
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    DailyStatusCard(
        hasSeenFactToday: true,
        category: Category(name: "Science", icon: "🔬", color: .blue),
        showingFactView: .constant(false),
        selectedCategory: .constant(nil)
    )
}
