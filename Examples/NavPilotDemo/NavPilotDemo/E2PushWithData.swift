//
//  E2PushWithData.swift
//  NavPilot
//
//  Created by DK on 02/04/26.
//

import SwiftUI
import NavPilot


struct E2Product: Hashable {
    let id: Int
    let name: String
}

enum E2Route: Hashable {
    case catalog
    case product(E2Product)
    case checkout(items: [String])
    case confirmation
}

struct E2PushWithData: View {
    @StateObject var pilot = NavPilot(initial: E2Route.catalog)

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .catalog:              E2CatalogView()
            case .product(let p):       E2ProductView(product: p)
            case .checkout(let items):  E2CheckoutView(items: items)
            case .confirmation:         E2ConfirmationView()
            }
        }
    }
}

struct E2CatalogView: View {
    @EnvironmentObject var pilot: NavPilot<E2Route>
    let products = [
        E2Product(id: 1, name: "Keyboard"),
        E2Product(id: 2, name: "Monitor"),
        E2Product(id: 3, name: "Mouse"),
    ]

    var body: some View {
        List(products, id: \.id) { product in
            Button(product.name) {
                pilot.push(.product(product))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.mint)
        .navigationTitle("Catalog")
    }
}

struct E2ProductView: View {
    @EnvironmentObject var pilot: NavPilot<E2Route>
    let product: E2Product

    var body: some View {
        VStack(spacing: 20) {
            Text(product.name).font(.title)
            Text("ID: \(product.id)").foregroundStyle(.secondary)

            Button("Buy Now") {
                // Push checkout with item list, then skip back later
                pilot.push(.checkout(items: [product.name]))
            }
            Button("Replace with Monitor") {
                pilot.replaceCurrent(with: .product(E2Product(id: 2, name: "Monitor")))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.green)
        .navigationTitle(product.name)
    }
}

struct E2CheckoutView: View {
    @EnvironmentObject var pilot: NavPilot<E2Route>
    let items: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text("Items: \(items.joined(separator: ", "))")
            Button("Confirm Order") {
                // Replace entire stack: catalog → confirmation (skip checkout on back)
                pilot.replace([.catalog, .confirmation])
            }
            Button("Go Back 1 step") { pilot.pop() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.cyan)
        .navigationTitle("Checkout")
    }
}

struct E2ConfirmationView: View {
    @EnvironmentObject var pilot: NavPilot<E2Route>

    var body: some View {
        VStack(spacing: 20) {
            Text("Order Confirmed! 🎉").font(.title2)
            Button("Back to Catalog") { pilot.popToRoot() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.yellow)
        .navigationTitle("Confirmation")
    }
}
