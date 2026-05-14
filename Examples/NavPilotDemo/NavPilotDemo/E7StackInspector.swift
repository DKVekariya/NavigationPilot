//
//  E7StackInspector.swift
//  NavPilotDemo
//
//  Created by DK on 14/05/26.
//

import SwiftUI
import NavPilot

enum E7Route: Hashable {
    case home
    case detail(id: Int)
    case settings
}

struct E7StackInspector: View {
    @StateObject private var pilot = NavPilot(initial: E7Route.home, debug: true)
    @State private var showsInspector = true

    var body: some View {
        NavPilotHost(pilot, showsStackInspector: showsInspector) { route in
            switch route {
            case .home:
                E7HomeView(showsInspector: $showsInspector)
            case .detail(let id):
                E7DetailView(id: id)
            case .settings:
                E7SettingsView()
            }
        }
    }
}

struct E7HomeView: View {
    @EnvironmentObject var pilot: NavPilot<E7Route>
    @Binding var showsInspector: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Stack Inspector")
                .font(.largeTitle.bold())

            Text("Turn the inspector on or off and watch the current stack update while you navigate.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Toggle("Show Inspector", isOn: $showsInspector)
                .padding(.horizontal)

            Button("Go to Detail") {
                pilot.push(.detail(id: 1))
            }

            Button("Go to Settings") {
                pilot.push(.settings)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Home")
    }
}

struct E7DetailView: View {
    @EnvironmentObject var pilot: NavPilot<E7Route>
    let id: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Detail \(id)")
                .font(.title.bold())
            Text("Look at the inspector overlay to see this route appear in the stack.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Go to Settings") {
                pilot.push(.settings)
            }

            Button("Pop") {
                pilot.pop()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Detail")
    }
}

struct E7SettingsView: View {
    @EnvironmentObject var pilot: NavPilot<E7Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title.bold())
            Text("The inspector makes it easier to understand how the stack changes during navigation.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Pop To Root") {
                pilot.popToRoot()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
    }
}
