import SwiftUI

struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    @Namespace private var animation
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .matchedGeometryEffect(id: "background", in: animation)
                        .frame(width: 80, height: 80)
                    
                    if isSelected {
                        Circle()
                            .stroke(category.color.opacity(0.3), lineWidth: 2)
                            .matchedGeometryEffect(id: "outline", in: animation)
                            .frame(width: 80, height: 80)
                    }
                    
                    Text(category.icon)
                        .font(.system(size: 36))
                        .matchedGeometryEffect(id: "icon", in: animation)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                
                // Category name with gradient
                Text(category.name)
                    .font(.headline)
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
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: category.color.opacity(isSelected ? 0.3 : 0.1),
                        radius: isSelected ? 15 : 10,
                        x: 0,
                        y: isSelected ? 8 : 5
                    )
                    .matchedGeometryEffect(id: "card", in: animation)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(category.color.opacity(0.3), lineWidth: 2)
                        .matchedGeometryEffect(id: "border", in: animation)
                }
            }
        }
        .buttonStyle(CategoryButtonStyle())
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered = hovering && !isDisabled
            }
        }
    }
}

struct CategoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    CategoryCard(
        category: Category(name: "Science", icon: "🔬", color: .blue),
        isSelected: false,
        isDisabled: false,
        onTap: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
