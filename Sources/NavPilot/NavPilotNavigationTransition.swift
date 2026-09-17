import SwiftUI

#if canImport(UIKitNavigationTransitions)
import UIKitNavigationTransitions
#endif

/// Visual style used when NavPilot pushes or pops a route.
///
/// Pass a value to `push(_:withAnimation:)` to opt in for that route. Omitting it
/// preserves the system navigation transition.
public enum NavPilotNavigationTransition: String, CaseIterable, Hashable, Identifiable, Sendable {
    case slide
    case slideVertical
    case fadeIn
    case fadeOut
    case crossDissolve
    case scale
    case zoom
    case flip
    case windmill

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .slide: "Slide"
        case .slideVertical: "Vertical Slide"
        case .fadeIn: "Fade In"
        case .fadeOut: "Fade Out"
        case .crossDissolve: "Cross Dissolve"
        case .scale: "Scale"
        case .zoom: "Zoom"
        case .flip: "Flip"
        case .windmill: "Windmill"
        }
    }
}

#if canImport(UIKitNavigationTransitions)
internal extension NavPilotNavigationTransition {
    var nativeTransition: UIKitNavigationTransitions.AnyNavigationTransition {
        switch self {
        case .slide:
            .slide.animation(.easeInOut(duration: 0.32))
        case .slideVertical:
            .slide(axis: .vertical).animation(.easeInOut(duration: 0.32))
        case .fadeIn:
            .fade(.in).animation(.easeInOut(duration: 0.25))
        case .fadeOut:
            .fade(.out).animation(.easeInOut(duration: 0.25))
        case .crossDissolve:
            .fade(.cross).animation(.easeInOut(duration: 0.3))
        case .scale:
            UIKitNavigationTransitions.AnyNavigationTransition(
                UIKitNavigationTransitions.MirrorPush { UIKitNavigationTransitions.Scale(0.82) }
            )
                .combined(with: .fade(.cross))
                .animation(.interpolatingSpring(stiffness: 280, damping: 24))
        case .zoom:
            UIKitNavigationTransitions.AnyNavigationTransition(
                UIKitNavigationTransitions.MirrorPush { UIKitNavigationTransitions.Scale(0.5) }
            )
                .combined(with: .fade(.in))
                .animation(.interpolatingSpring(stiffness: 230, damping: 20))
        case .flip:
            UIKitNavigationTransitions.AnyNavigationTransition(UIKitNavigationTransitions.MirrorPush {
                UIKitNavigationTransitions.Rotate3D(
                    .degrees(75),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: -1
                )
            })
            .animation(.easeInOut(duration: 0.4))
        case .windmill:
            UIKitNavigationTransitions.AnyNavigationTransition(
                UIKitNavigationTransitions.MirrorPush {
                    UIKitNavigationTransitions.Rotate(.degrees(90))
                }
            )
                .combined(with: .fade(.cross))
                .animation(.easeInOut(duration: 0.42))
        }
    }
}
#endif
