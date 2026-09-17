//
//  E8RouteGuards.swift
//  NavPilotDemo
//

import Combine
import SwiftUI
import NavPilot

enum E8Route: Hashable {
    case home
    case publicProfile
    case accountSettings
}

@MainActor
final class E8Access: ObservableObject {
    @Published var isSignedIn = false
}

struct E8RouteGuards: View {
    @StateObject private var access: E8Access
    @StateObject private var pilot: NavPilot<E8Route>

    init() {
        let access = E8Access()
        _access = StateObject(wrappedValue: access)
        _pilot = StateObject(wrappedValue: NavPilot(initial: .home) { route, _ in
            route != .accountSettings || access.isSignedIn
        })
    }

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .home:
                E8HomeView(access: access)
            case .publicProfile:
                E8PublicProfileView()
            case .accountSettings:
                E8AccountSettingsView()
            }
        }
    }
}

private struct E8HomeView: View {
    @EnvironmentObject private var pilot: NavPilot<E8Route>
    @ObservedObject var access: E8Access

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Route Guards")
                .font(.largeTitle.bold())

            Text("Public Profile is always available. Account Settings can only be pushed after signing in.")
                .foregroundStyle(.secondary)

            Toggle("Signed in", isOn: $access.isSignedIn)

            Button("Open Public Profile") {
                pilot.push(.publicProfile)
            }

            Button("Open Account Settings") {
                pilot.push(.accountSettings)
            }
            .buttonStyle(.borderedProminent)

            Text(access.isSignedIn ? "Settings access is currently allowed." : "Settings access is currently blocked. Turn on Signed in, then try again.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("Home")
    }
}

private struct E8PublicProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
            Text("Public Profile")
                .font(.title.bold())
            Text("This route is not guarded.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Profile")
    }
}

private struct E8AccountSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
            Text("Account Settings")
                .font(.title.bold())
            Text("The route guard allowed this protected screen.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Settings")
    }
}
