//
//  E6StatePersistence.swift
//  NavPilotDemo
//
//  Created by DK on 14/05/26.
//

import Foundation
import SwiftUI
import NavPilot

struct E6Product: Codable, Hashable, Equatable {
    let id: Int
    let name: String
}

enum E6Route: Codable, Hashable {
    case home
    case product(E6Product)
    case checkout(items: [String])
}

struct E6StatePersistence: View {
    @StateObject private var pilot = NavPilot(
        initial: E6Route.home,
        debug: true,
        // Set `persistState` to false to disable stack restoration.
        // Enable it only when the route carries enough Codable data to recreate the screen
        // and its view model after relaunch.
        persistState: true,
        persistenceKey: "NavPilotDemo.E6StatePersistence"
    )

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .home:
                E6HomeView()
            case .product(let product):
                E6ProductView(product: product)
            case .checkout(let items):
                E6CheckoutView(items: items)
            }
        }
    }
}

struct E6HomeView: View {
    @EnvironmentObject var pilot: NavPilot<E6Route>

    let products = [
        E6Product(id: 1, name: "Keyboard"),
        E6Product(id: 2, name: "Monitor"),
        E6Product(id: 3, name: "Mouse")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("State Persistence")
                    .font(.largeTitle.bold())

                Text("This demo saves the stack automatically. Push a few screens, quit the app, then reopen it to see the stack restored.")
                    .foregroundStyle(.secondary)

                Text("Use persistence only when the route contains enough Codable data to rebuild the screen. View models and injected services are created again when the app restores the route stack.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(products, id: \.id) { product in
                        Button {
                            pilot.push(.product(product))
                        } label: {
                            Label(product.name, systemImage: "chevron.right")
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Button("Add Checkout") {
                    pilot.push(.checkout(items: ["Keyboard", "Mouse"]))
                }

                Button("Pop To Root") {
                    pilot.popToRoot()
                }

                Button(role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "NavPilotDemo.E6StatePersistence")
                    pilot.popToRoot()
                } label: {
                    Text("Clear Saved Stack")
                }

                Text("If your screen depends on a view model, recreate that view model from the route data or from your app container. The persisted stack only stores navigation state, not live objects.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Current stack")
                        .font(.headline)
                    Text(String(describing: pilot.stack))
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Home")
    }
}

struct E6ProductView: View {
    @EnvironmentObject var pilot: NavPilot<E6Route>
    let product: E6Product

    var body: some View {
        VStack(spacing: 20) {
            Text(product.name).font(.title2.bold())
            Text("This screen will be restored after relaunch if persistence is enabled.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Checkout") {
                pilot.push(.checkout(items: [product.name]))
            }

            Button("Back") {
                pilot.pop()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(product.name)
    }
}

struct E6CheckoutView: View {
    @EnvironmentObject var pilot: NavPilot<E6Route>
    let items: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text("Checkout").font(.title2.bold())
            Text(items.joined(separator: ", "))
                .foregroundStyle(.secondary)
            Text("After you relaunch the app, this screen should still be on the stack.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Pop To Root") {
                pilot.popToRoot()
            }

            Button("Back") {
                pilot.pop()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Checkout")
    }
}
