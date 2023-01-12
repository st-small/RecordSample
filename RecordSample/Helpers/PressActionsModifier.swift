import SwiftUI

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onTrash: () -> Void
    var onLock: () -> Void
    var onRelease: () -> Void
    
    @State private var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        onPress()
                        isPressed = true
                    }
                    .onEnded { value in
                        let width = abs(value.translation.width)
                        let height = abs(value.translation.height)
                        
                        if width < 5 && height < 5 {
                            onRelease()
                        } else if width > height {
                            onTrash()
                        } else if width < height {
                            onLock()
                        }
                        
                        isPressed = false
                    }
            )
    }
}


extension View {
    func pressAction(onPress: @escaping (() -> Void), onTrash: @escaping (() -> Void), onLock: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(
            PressActions(
                onPress: { onPress() },
                onTrash: { onTrash() },
                onLock: { onLock() },
                onRelease: { onRelease() }
            )
        )
    }
}
