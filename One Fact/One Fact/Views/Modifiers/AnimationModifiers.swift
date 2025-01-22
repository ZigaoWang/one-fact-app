import SwiftUI

struct PressAnimation: ViewModifier {
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func pressAnimation(isPressed: Bool) -> some View {
        modifier(PressAnimation(scale: isPressed ? 0.95 : 1.0))
    }
    
    func shake(animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(animatableData: animatableData))
    }
}
