//
//  E5DeepLinking.swift
//  NavPilotDemo
//
//  Created by DK on 14/05/26.
//

import SwiftUI
import NavPilot

struct E5CatalogProduct: Codable, Hashable, Equatable {
    let id: Int
    let name: String
}

enum E5Route: Codable, Hashable {
    case home
    case product(E5CatalogProduct)
    case checkout(items: [String])
}

struct E5DeepLinking: View {
    @StateObject private var pilot = NavPilot(initial: E5Route.home, debug: true)
    @State private var deepLinkString: String = ""
    @State private var status: String = "Tap Generate to create a deep link for the current stack."

    var body: some View {
        NavPilotHost(pilot) { route in
            switch route {
            case .home:
                E5HomeView(
                    deepLinkString: $deepLinkString,
                    status: $status
                )
            case .product(let product):
                E5ProductView(product: product)
            case .checkout(let items):
                E5CheckoutView(items: items)
            }
        }
    }
}

struct E5HomeView: View {
    @EnvironmentObject var pilot: NavPilot<E5Route>
    @Binding var deepLinkString: String
    @Binding var status: String

    let products = [
        E5CatalogProduct(id: 1, name: "Keyboard"),
        E5CatalogProduct(id: 2, name: "Monitor"),
        E5CatalogProduct(id: 3, name: "Mouse")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Deep Linking")
                    .font(.largeTitle.bold())

                Text("Build a stack, export it to a URL, then restore it later.")
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

                Button("Generate Deep Link") {
                    deepLinkString = pilot.deepLinkURL()?.absoluteString ?? ""
                    status = deepLinkString.isEmpty
                    ? "Current stack could not be encoded."
                    : "Deep link generated from the current stack."
                }

                TextEditor(text: $deepLinkString)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                Button("Restore From Deep Link") {
                    guard let url = URL(string: deepLinkString) else {
                        status = "The URL is invalid."
                        return
                    }

                    let handled = pilot.handleDeepLink(url)
                    status = handled
                    ? "Deep link restored successfully."
                    : "That deep link could not be restored."
                }

                Button("Pop To Root") {
                    pilot.popToRoot()
                }

                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Home")
    }
}

struct E5ProductView: View {
    @EnvironmentObject var pilot: NavPilot<E5Route>
    let product: E5CatalogProduct

    var body: some View {
        VStack(spacing: 20) {
            Text(product.name).font(.title2.bold())
            Text("This screen is part of the deep-link stack.")
                .foregroundStyle(.secondary)
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

struct E5CheckoutView: View {
    @EnvironmentObject var pilot: NavPilot<E5Route>
    let items: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text("Checkout").font(.title2.bold())
            Text(items.joined(separator: ", "))
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
