//
//  NavPilotHost.swift
//  NavPilot
//
//  Created by DK on 14/05/26.
//

import SwiftUI

#if canImport(UIKit) && canImport(UIKitNavigationTransitions)
import UIKit
import UIKitNavigationTransitions
#endif


public struct NavPilotHost<T: Hashable, Screen: View>: View {

    @ObservedObject private var pilot: NavPilot<T>
    private let buildScreen: (T) -> Screen
    private let showsStackInspector: Bool

    public init(
        _ pilot: NavPilot<T>,
        showsStackInspector: Bool = false,
        @ViewBuilder buildScreen: @escaping (T) -> Screen
    ) {
        self.pilot = pilot
        self.buildScreen = buildScreen
        self.showsStackInspector = showsStackInspector
    }

    public var body: some View {
        if let root = pilot.stack.first {
            ZStack(alignment: .bottom) {
                NavigationStack(path: tailBinding) {
                    buildScreen(root)
                        .navigationDestination(for: T.self) { route in
                            buildScreen(route)
                                .environmentObject(pilot)
                        }
                        .environmentObject(pilot)
                        #if canImport(UIKit) && canImport(UIKitNavigationTransitions)
                        .background(NavPilotTransitionBridge(pilot: pilot).frame(width: 0, height: 0))
                        #endif
                }
                .environmentObject(pilot)

                if showsStackInspector {
                    NavPilotStackInspector(pilot)
                        .allowsHitTesting(false)
                }
            }
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

#if canImport(UIKit) && canImport(UIKitNavigationTransitions)
private struct NavPilotTransitionBridge<T: Hashable>: UIViewControllerRepresentable {
    let pilot: NavPilot<T>

    func makeUIViewController(context: Context) -> BridgeController {
        BridgeController()
    }

    func updateUIViewController(_ controller: BridgeController, context: Context) {
        DispatchQueue.main.async {
            guard let navigationController = controller.navigationController else { return }
            pilot.setTransitionApplier { [weak navigationController] transition in
                navigationController?.setNavigationTransition(
                    transition?.nativeTransition ?? .default
                )
            }
        }
    }

    final class BridgeController: UIViewController {}
}
#endif

// ─────────────────────────────────────────────────────────────
// MARK: - Convenience modifier
// ─────────────────────────────────────────────────────────────

extension View {
    /// Nest a NavPilotHost inside any view. Handy for split-screen.
    public func piloted<T: Hashable, Screen: View>(
        by pilot: NavPilot<T>,
        showsStackInspector: Bool = false,
        @ViewBuilder buildScreen: @escaping (T) -> Screen
    ) -> some View {
        NavPilotHost(pilot, showsStackInspector: showsStackInspector, buildScreen: buildScreen)
    }
}
