//
//  NavPilot.swift
//  NavPilot
//
//  Created by DK on 07/04/26.
//

import SwiftUI
import Combine

// MARK: - NavPilot  (the router / state holder)

/// Observable router that owns the navigation path.
/// `T` must be `Hashable` so NavigationStack can drive itself.
public final class NavPilot<T: Hashable>: ObservableObject {

    /// The live navigation stack. Index 0 is always the root.
    @Published public private(set) var stack: [T]

    /// Convenience: the route currently at the top of the stack.
    public var current: T? { stack.last }

    /// Initialise with a root route.
    public init(initial: T) {
        self.stack = [initial]
    }

    // ── Push ──────────────────────────────────────────────────

    /// Push one route onto the stack.
    public func push(_ route: T) {
        stack.append(route)
    }

    /// Push multiple routes at once (pushed in the order given).
    public func push(_ routes: T...) {
        stack.append(contentsOf: routes)
    }

    // ── Pop ───────────────────────────────────────────────────

    /// Pop the top route. No-op if already at root.
    public func pop() {
        guard stack.count > 1 else { return }
        stack.removeLast()
    }

    /// Pop `n` routes at once. Always keeps the root.
    public func pop(count n: Int) {
        let removeCount = min(n, stack.count - 1)
        guard removeCount > 0 else { return }
        stack.removeLast(removeCount)
    }

    /// Pop back to the first occurrence of `route`.
    /// Stack is unchanged if `route` is not found.
    public func popTo(_ route: T) {
        guard let idx = stack.firstIndex(of: route) else { return }
        stack = Array(stack.prefix(through: idx))
    }

    /// Pop everything back to the root.
    public func popToRoot() {
        guard let root = stack.first else { return }
        stack = [root]
    }

    // ── Replace ───────────────────────────────────────────────

    /// Replace the entire stack. The first element becomes the new root.
    public func replace(_ routes: [T]) {
        guard !routes.isEmpty else { return }
        stack = routes
    }

    /// Swap only the top-most route.
    public func replaceCurrent(with route: T) {
        guard !stack.isEmpty else { return }
        stack[stack.count - 1] = route
    }

    // ── Internal ──────────────────────────────────────────────

    /// Called by NavPilotHost to sync the stack after a native swipe-back.
    func syncTail(_ tail: [T]) {
        guard let root = stack.first else { return }
        stack = [root] + tail
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - NavPilotHost  (root view)
// ─────────────────────────────────────────────────────────────

/// Place this once at the root of your scene.
///
///     NavPilotHost(pilot) { route in
///         switch route {
///         case .home:   HomeView()
///         case .detail: DetailView()
///         }
///     }
public struct NavPilotHost<T: Hashable, Screen: View>: View {

    @ObservedObject private var pilot: NavPilot<T>
    private let buildScreen: (T) -> Screen

    public init(
        _ pilot: NavPilot<T>,
        @ViewBuilder buildScreen: @escaping (T) -> Screen
    ) {
        self.pilot = pilot
        self.buildScreen = buildScreen
    }

    public var body: some View {
        if let root = pilot.stack.first {
            NavigationStack(path: tailBinding) {
                buildScreen(root)
                    .navigationDestination(for: T.self) { route in
                        buildScreen(route)
                            .environmentObject(pilot)
                    }
                    .environmentObject(pilot)
            }
            .environmentObject(pilot)
        }
    }

    /// Binding for everything after index 0 (the "tail").
    private var tailBinding: Binding<[T]> {
        Binding(
            get: { Array(pilot.stack.dropFirst()) },
            set: { pilot.syncTail($0) }   // keeps root + syncs swipe-back
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Convenience modifier
// ─────────────────────────────────────────────────────────────

extension View {
    /// Nest a NavPilotHost inside any view. Handy for split-screen.
    public func piloted<T: Hashable, Screen: View>(
        by pilot: NavPilot<T>,
        @ViewBuilder buildScreen: @escaping (T) -> Screen
    ) -> some View {
        NavPilotHost(pilot, buildScreen: buildScreen)
    }
}







