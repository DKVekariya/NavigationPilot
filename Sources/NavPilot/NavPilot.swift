//
//  NavPilot.swift
//  NavPilot
//
//  Created by DK on 07/04/26.
//

import SwiftUI
import Combine

/// Describes the navigation request being evaluated by a route guard.
public enum NavPilotNavigationAction: Sendable {
    case push
    case replace
    case replaceCurrent
    case deepLink
}

/// A synchronous policy used to allow or deny programmatic navigation.
/// Return `true` to allow the route or `false` to keep the current stack unchanged.
public typealias NavPilotRouteGuard<T> = (T, NavPilotNavigationAction) -> Bool

// MARK: - NavPilot  (the router / state holder)

/// Observable router that owns the navigation path.
/// `T` must be `Hashable` so NavigationStack can drive itself.
@MainActor
public final class NavPilot<T: Hashable>: ObservableObject {
    private let debug: Bool
    private let persistenceHandler: (([T]) -> Void)?
    private let routeGuard: NavPilotRouteGuard<T>?
    private var routeTransitions: [NavPilotNavigationTransition?]
    private var transitionApplier: ((NavPilotNavigationTransition?) -> Void)?

    /// The live navigation stack. Index 0 is always the root.
    @Published public private(set) var stack: [T]

    /// Convenience: the route currently at the top of the stack.
    public var current: T? { stack.last }

    /// Number of routes currently in the stack.
    public var depth: Int { stack.count }

    /// Initialize with a root route.
    public init(
        initial: T,
        debug: Bool = false,
        routeGuard: NavPilotRouteGuard<T>? = nil
    ) {
        self.debug = debug
        self.persistenceHandler = nil
        self.routeGuard = routeGuard
        self.stack = [initial]
        self.routeTransitions = [nil]
        NavPilotLogger.log(enabled: debug, "init \(stackDescription())")
    }

    private init(
        initial: T,
        debug: Bool,
        loadedStack: [T]?,
        persistenceHandler: (([T]) -> Void)?,
        routeGuard: NavPilotRouteGuard<T>?
    ) {
        let restoredStack = loadedStack ?? [initial]
        self.debug = debug
        self.persistenceHandler = persistenceHandler
        self.routeGuard = routeGuard
        self.stack = restoredStack
        self.routeTransitions = Array(repeating: nil, count: restoredStack.count)
        NavPilotLogger.log(enabled: debug, "init \(stackDescription())")
        persistIfNeeded()
    }

    // ── Push ──────────────────────────────────────────────────

    /// Push one route onto the stack.
    public func push(_ route: T) {
        push(route, withAnimation: nil)
    }

    /// Push one route using an optional custom transition.
    ///
    /// Passing `nil` keeps the platform's normal navigation transition. The same transition
    /// is used when this route is later popped.
    public func push(_ route: T, withAnimation animation: NavPilotNavigationTransition?) {
        guard allows(route, action: .push) else { return }
        applyTransition(animation)
        stack.append(route)
        routeTransitions.append(animation)
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "push \(describe(route)) -> \(stackDescription())")
    }

    /// Push multiple routes at once (pushed in the order given).
    public func push(_ routes: T...) {
        push(routes, withAnimation: nil)
    }

    /// Push multiple routes using the same optional custom transition.
    public func push(_ routes: [T], withAnimation animation: NavPilotNavigationTransition?) {
        guard !routes.isEmpty else {
            NavPilotLogger.log(enabled: debug, "push ignored: no routes -> \(stackDescription())")
            return
        }
        guard routes.allSatisfy({ allows($0, action: .push) }) else { return }
        applyTransition(animation)
        stack.append(contentsOf: routes)
        routeTransitions.append(contentsOf: Array(repeating: animation, count: routes.count))
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "push \(routes.map(describe).joined(separator: ", ")) -> \(stackDescription())")
    }

    // ── Pop ───────────────────────────────────────────────────

    /// Pop the top route. No-op if already at root.
    public func pop() {
        guard stack.count > 1 else {
            NavPilotLogger.log(enabled: debug, "pop ignored at root -> \(stackDescription())")
            return
        }
        applyTransition(routeTransitions.last ?? nil)
        stack.removeLast()
        routeTransitions.removeLast()
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "pop -> \(stackDescription())")
    }

    /// Pop `n` routes at once. Always keeps the root.
    public func pop(count n: Int) {
        let removeCount = min(n, stack.count - 1)
        guard removeCount > 0 else {
            NavPilotLogger.log(enabled: debug, "pop(count: \(n)) ignored -> \(stackDescription())")
            return
        }
        applyTransition(routeTransitions.last ?? nil)
        stack.removeLast(removeCount)
        routeTransitions.removeLast(removeCount)
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "pop(count: \(n)) -> \(stackDescription())")
    }

    /// Pop back to the first occurrence of `route`.
    /// Stack is unchanged if `route` is not found.
    public func popTo(_ route: T) {
        guard let idx = stack.firstIndex(of: route) else {
            NavPilotLogger.log(enabled: debug, "popTo \(describe(route)) ignored (not found) -> \(stackDescription())")
            return
        }
        applyTransition(routeTransitions.last ?? nil)
        stack = Array(stack.prefix(through: idx))
        routeTransitions = Array(routeTransitions.prefix(through: idx))
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "popTo \(describe(route)) -> \(stackDescription())")
    }

    /// Pop back to the last occurrence of `route`.
    /// Stack is unchanged if `route` is not found.
    public func popToLast(_ route: T) {
        guard let idx = stack.lastIndex(of: route) else {
            NavPilotLogger.log(enabled: debug, "popToLast \(describe(route)) ignored (not found) -> \(stackDescription())")
            return
        }
        applyTransition(routeTransitions.last ?? nil)
        stack = Array(stack.prefix(through: idx))
        routeTransitions = Array(routeTransitions.prefix(through: idx))
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "popToLast \(describe(route)) -> \(stackDescription())")
    }

    /// Pop everything back to the root.
    public func popToRoot() {
        guard let root = stack.first else {
            NavPilotLogger.log(enabled: debug, "popToRoot ignored -> []")
            return
        }
        applyTransition(routeTransitions.last ?? nil)
        stack = [root]
        routeTransitions = [nil]
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "popToRoot -> \(stackDescription())")
    }

    // ── Replace ───────────────────────────────────────────────

    /// Replace the entire stack. The first element becomes the new root.
    public func replace(_ routes: [T]) {
        guard !routes.isEmpty else {
            NavPilotLogger.log(enabled: debug, "replace ignored: [] -> \(stackDescription())")
            return
        }
        guard routes.allSatisfy({ allows($0, action: .replace) }) else { return }
        applyTransition(nil)
        stack = routes
        routeTransitions = Array(repeating: nil, count: routes.count)
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "replace -> \(stackDescription())")
    }

    /// Swap only the top-most route.
    public func replaceCurrent(with route: T) {
        guard !stack.isEmpty else {
            NavPilotLogger.log(enabled: debug, "replaceCurrent \(describe(route)) ignored -> []")
            return
        }
        guard allows(route, action: .replaceCurrent) else { return }
        applyTransition(nil)
        stack[stack.count - 1] = route
        routeTransitions[routeTransitions.count - 1] = nil
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "replaceCurrent \(describe(route)) -> \(stackDescription())")
    }

    // ── Internal ──────────────────────────────────────────────

    /// Called by NavPilotHost to sync the stack after a native swipe-back.
    func syncTail(_ tail: [T]) {
        guard let root = stack.first else {
            NavPilotLogger.log(enabled: debug, "syncTail ignored -> []")
            return
        }
        stack = [root] + tail
        routeTransitions = Array(routeTransitions.prefix(tail.count + 1))
        if routeTransitions.count != stack.count {
            routeTransitions = Array(repeating: nil, count: stack.count)
        }
        applyTransition(routeTransitions.last ?? nil)
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "syncTail -> \(stackDescription())")
    }

    /// Generate a deep-link URL for the current stack.
    public func deepLinkURL(scheme: String = "navpilot", host: String = "stack") -> URL? where T: Codable {
        NavPilotDeepLinkCodec.makeURL(from: stack, scheme: scheme, host: host)
    }

    /// Replace the current stack from a deep-link URL.
    /// Returns `true` when the URL could be decoded into a non-empty stack.
    @discardableResult
    public func handleDeepLink(_ url: URL, scheme: String = "navpilot", host: String = "stack") -> Bool where T: Codable {
        let routes: [T]? = NavPilotDeepLinkCodec.decode(url, expectedScheme: scheme, expectedHost: host)
        guard let routes, !routes.isEmpty else {
            NavPilotLogger.log(enabled: debug, "deepLink ignored -> \(url.absoluteString)")
            return false
        }
        guard routes.allSatisfy({ allows($0, action: .deepLink) }) else { return false }

        applyTransition(nil)
        stack = routes
        routeTransitions = Array(repeating: nil, count: routes.count)
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "deepLink handled -> \(stackDescription())")
        return true
    }

    private func describe(_ route: T) -> String {
        String(describing: route)
    }

    private func stackDescription(_ routes: [T]? = nil) -> String {
        let values = (routes ?? stack).map(describe)
        return "[" + values.joined(separator: " -> ") + "]"
    }

    private func persistIfNeeded() {
        persistenceHandler?(stack)
    }

    func setTransitionApplier(_ applier: @escaping (NavPilotNavigationTransition?) -> Void) {
        transitionApplier = applier
        applyTransition(routeTransitions.last ?? nil)
    }

    private func applyTransition(_ transition: NavPilotNavigationTransition?) {
        transitionApplier?(transition)
    }

    private func allows(_ route: T, action: NavPilotNavigationAction) -> Bool {
        guard let routeGuard else { return true }
        guard routeGuard(route, action) else {
            NavPilotLogger.log(enabled: debug, "\(actionDescription(action)) blocked \(describe(route)) -> \(stackDescription())")
            return false
        }
        return true
    }

    private func actionDescription(_ action: NavPilotNavigationAction) -> String {
        switch action {
        case .push: "push"
        case .replace: "replace"
        case .replaceCurrent: "replaceCurrent"
        case .deepLink: "deepLink"
        }
    }
}

public extension NavPilot where T: Codable {
    /// Create a pilot that can optionally restore and save its route stack.
    ///
    /// Set `persistState` to `true` to enable automatic persistence, or leave it `false`
    /// to keep navigation state in-memory only.
    ///
    /// This works best when each route contains enough `Codable` data to recreate the screen
    /// and its view model after relaunch. It can fail to restore meaningfully if a screen
    /// depends on runtime-only values, closures, or non-codable objects that are not present
    /// in the route data.
    convenience init(
        initial: T,
        debug: Bool = false,
        persistState: Bool = false,
        persistenceKey: String? = nil,
        routeGuard: NavPilotRouteGuard<T>? = nil
    ) {
        let key = NavPilotPersistence.defaultKey(for: T.self, customKey: persistenceKey)
        let loaded: [T]? = persistState ? NavPilotPersistence.loadStack(forKey: key) : nil
        let handler: (([T]) -> Void)? = persistState ? { stack in
            NavPilotPersistence.saveStack(stack, forKey: key)
        } : nil
        self.init(
            initial: initial,
            debug: debug,
            loadedStack: loaded,
            persistenceHandler: handler,
            routeGuard: routeGuard
        )
    }
}
