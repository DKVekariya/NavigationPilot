//
//  E3CloserPass.swift
//  NavPilot
//
//  Created by DK on 02/04/26.
//

import SwiftUI
import NavPilot

enum E3Route: Hashable {
    case start
    case home
    case signIn
    case profile(onSignOut: () -> Void)

    // Closures can't be auto-synthesised — implement manually.
    func hash(into hasher: inout Hasher) {
        switch self {
        case .start:    hasher.combine(0)
        case .home:     hasher.combine(1)
        case .signIn:   hasher.combine(2)
        case .profile:  hasher.combine(3)
        }
    }
    static func == (lhs: E3Route, rhs: E3Route) -> Bool {
        switch (lhs, rhs) {
        case (.start,   .start):   return true
        case (.home,    .home):    return true
        case (.signIn,  .signIn):  return true
        case (.profile, .profile): return true
        default:                   return false
        }
    }
}

struct E3CloserPass: View {
    @StateObject var pilot = NavPilot(initial: E3Route.start)

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .start:                 E3StartView()
            case .home:                  E3HomeView()
            case .signIn:                E3SignInView()
            case .profile(let onSignOut): E3ProfileView(onSignOut: onSignOut)
            }
        }
    }
}

struct E3StartView: View {
    @EnvironmentObject var pilot: NavPilot<E3Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome").font(.largeTitle)
            Button("Let's Start") { pilot.push(.home) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.mint)
        .navigationTitle("Start")
    }
}

struct E3HomeView: View {
    @EnvironmentObject var pilot: NavPilot<E3Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("You're logged out")
            Button("Sign In") { pilot.push(.signIn) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.green)
        .navigationTitle("Home")
    }
}

struct E3SignInView: View {
    @EnvironmentObject var pilot: NavPilot<E3Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in to continue")
            Button("Go to Profile") {
                // Pass a callback closure; Profile calls it to trigger sign-out
                pilot.push(.profile(onSignOut: {
                    pilot.popTo(.home)   // fired when user taps Sign Out in Profile
                }))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.cyan)
        .navigationTitle("Sign In")
    }
}

struct E3ProfileView: View {
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, User 👋")
            Button("Sign Out", role: .destructive) {
                onSignOut()   // calls pilot.popTo(.home) defined above
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.yellow)
        .navigationTitle("Profile")
    }
}
