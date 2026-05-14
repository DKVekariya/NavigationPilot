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
    private let debug: Bool
    private let persistenceHandler: (([T]) -> Void)?

    /// The live navigation stack. Index 0 is always the root.
    @Published public private(set) var stack: [T]

    /// Convenience: the route currently at the top of the stack.
    public var current: T? { stack.last }

    /// Number of routes currently in the stack.
    public var depth: Int { stack.count }

    /// Initialize with a root route.
    public init(initial: T, debug: Bool = false) {
        self.debug = debug
        self.persistenceHandler = nil
        self.stack = [initial]
        NavPilotLogger.log(enabled: debug, "init \(stackDescription())")
    }

    private init(initial: T, debug: Bool, loadedStack: [T]?, persistenceHandler: (([T]) -> Void)?) {
        self.debug = debug
        self.persistenceHandler = persistenceHandler
        self.stack = loadedStack ?? [initial]
        NavPilotLogger.log(enabled: debug, "init \(stackDescription())")
        persistIfNeeded()
    }

    // ── Push ──────────────────────────────────────────────────

    /// Push one route onto the stack.
    public func push(_ route: T) {
        stack.append(route)
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "push \(describe(route)) -> \(stackDescription())")
    }

    /// Push multiple routes at once (pushed in the order given).
    public func push(_ routes: T...) {
        guard !routes.isEmpty else {
            NavPilotLogger.log(enabled: debug, "push ignored: no routes -> \(stackDescription())")
            return
        }
        stack.append(contentsOf: routes)
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
        stack.removeLast()
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
        stack.removeLast(removeCount)
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
        stack = Array(stack.prefix(through: idx))
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
        stack = Array(stack.prefix(through: idx))
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "popToLast \(describe(route)) -> \(stackDescription())")
    }

    /// Pop everything back to the root.
    public func popToRoot() {
        guard let root = stack.first else {
            NavPilotLogger.log(enabled: debug, "popToRoot ignored -> []")
            return
        }
        stack = [root]
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
        stack = routes
        persistIfNeeded()
        NavPilotLogger.log(enabled: debug, "replace -> \(stackDescription())")
    }

    /// Swap only the top-most route.
    public func replaceCurrent(with route: T) {
        guard !stack.isEmpty else {
            NavPilotLogger.log(enabled: debug, "replaceCurrent \(describe(route)) ignored -> []")
            return
        }
        stack[stack.count - 1] = route
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

        stack = routes
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
    convenience init(initial: T, debug: Bool = false, persistState: Bool = false, persistenceKey: String? = nil) {
        let key = NavPilotPersistence.defaultKey(for: T.self, customKey: persistenceKey)
        let loaded: [T]? = persistState ? NavPilotPersistence.loadStack(forKey: key) : nil
        let handler: (([T]) -> Void)? = persistState ? { stack in
            NavPilotPersistence.saveStack(stack, forKey: key)
        } : nil
        self.init(initial: initial, debug: debug, loadedStack: loaded, persistenceHandler: handler)
    }
}
