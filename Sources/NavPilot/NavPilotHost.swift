//
//  NavPilotHost.swift
//  NavPilot
//
//  Created by DK on 14/05/26.
//

import SwiftUI


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
        } else {
            EmptyView()
                .onAppear {
                    assertionFailure("NavPilotHost requires a pilot with at least one route.")
                }
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
