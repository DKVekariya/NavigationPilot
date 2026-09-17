//
//  E9NavigationTransitions.swift
//  NavPilotDemo
//

import SwiftUI
import NavPilot

enum E9Route: Hashable {
    case home
    case detail(Int)
}

private enum E9TransitionChoice: String, CaseIterable, Identifiable {
    case system
    case slide
    case slideVertical
    case fadeIn
    case fadeOut
    case crossDissolve
    case scale
    case zoom
    case flip
    case windmill

    var id: String { rawValue }

    var title: String {
        transition?.title ?? "System Default"
    }

    var transition: NavPilotNavigationTransition? {
        switch self {
        case .system: nil
        case .slide: .slide
        case .slideVertical: .slideVertical
        case .fadeIn: .fadeIn
        case .fadeOut: .fadeOut
        case .crossDissolve: .crossDissolve
        case .scale: .scale
        case .zoom: .zoom
        case .flip: .flip
        case .windmill: .windmill
        }
    }
}

struct E9NavigationTransitions: View {
    @StateObject private var pilot = NavPilot(initial: E9Route.home)
    @State private var selectedTransition = E9TransitionChoice.slide

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .home:
                E9HomeView(selectedTransition: $selectedTransition)
            case .detail(let number):
                E9DetailView(number: number)
            }
        }
    }
}

private struct E9HomeView: View {
    @EnvironmentObject private var pilot: NavPilot<E9Route>
    @Binding var selectedTransition: E9TransitionChoice

    var body: some View {
        Form {
            Section("Transition") {
                Picker("Style", selection: $selectedTransition) {
                    ForEach(E9TransitionChoice.allCases) { transition in
                        Text(transition.title).tag(transition)
                    }
                }
            }

            Section {
                Button("Push Detail") {
                    pilot.push(.detail(pilot.depth), withAnimation: selectedTransition.transition)
                }
                .buttonStyle(.borderedProminent)
            } footer: {
                Text("Choose System Default to use the usual NavigationStack transition. Custom transitions reverse automatically when you pop.")
            }
        }
        .navigationTitle("Transitions")
    }
}

private struct E9DetailView: View {
    @EnvironmentObject private var pilot: NavPilot<E9Route>
    let number: Int

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 52))
            Text("Detail \(number)")
                .font(.title.bold())
            Text("Use the navigation back button, swipe back, or this button to see the matching reverse transition.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Pop") {
                pilot.pop()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Detail")
    }
}
