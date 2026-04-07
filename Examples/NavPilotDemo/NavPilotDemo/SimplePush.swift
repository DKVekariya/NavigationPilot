//
//  SimplePush.swift
//  NavPilot
//
//  Created by DK on 02/04/26.
//

import SwiftUI
import NavPilot

enum E1Route: Hashable {
    case home
    case detail(id: Int)
    case nestedDetail
}

struct Example1Root: View {
    @StateObject var pilot = NavPilot(initial: E1Route.home)

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .home:              E1HomeView()
            case .detail(let id):   E1DetailView(id: id)
            case .nestedDetail:     E1NestedDetailView()
            }
        }
    }
}

struct E1HomeView: View {
    @EnvironmentObject var pilot: NavPilot<E1Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("Home").font(.title)
            Button("Go to Detail (id: 11)") { pilot.push(.detail(id: 11)) }
        }
        .navigationTitle("Home")
    }
}

struct E1DetailView: View {
    @EnvironmentObject var pilot: NavPilot<E1Route>
    let id: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Detail — id: \(id)")
            Button("Go to Nested Detail") { pilot.push(.nestedDetail) }
            Button("Go Back")             { pilot.pop() }
        }
        .navigationTitle("Detail")
    }
}

struct E1NestedDetailView: View {
    @EnvironmentObject var pilot: NavPilot<E1Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("Nested Detail")
            Button("Pop to Home")  { pilot.popTo(.home) }
            Button("Pop to Root")  { pilot.popToRoot() }
        }
        .navigationTitle("Nested Detail")
    }
}

