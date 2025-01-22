import SwiftUI

struct SlideUpTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                )
            )
    }
}

extension AnyTransition {
    static var slideUp: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static func scaleAndFade(anchor: UnitPoint = .center) -> AnyTransition {
        AnyTransition.asymmetric(
            insertion: AnyTransition.scale(scale: 0.8, anchor: anchor)
                .combined(with: .opacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.7)),
            removal: AnyTransition.scale(scale: 0.8, anchor: anchor)
                .combined(with: .opacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.7))
        )
    }
}
