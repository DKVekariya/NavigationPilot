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
@MainActor
public final class NavPilot<T: Hashable>: ObservableObject {

    /// The live navigation stack. Index 0 is always the root.
    @Published public private(set) var stack: [T]

    /// Convenience: the route currently at the top of the stack.
    public var current: T? { stack.last }

    /// Number of routes currently in the stack.
    public var depth: Int { stack.count }

    /// Initialize with a root route.
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





