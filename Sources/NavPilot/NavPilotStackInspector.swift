//
//  NavPilotStackInspector.swift
//  NavPilot
//
//  Created by DK on 14/05/26.
//

import SwiftUI

@MainActor
internal struct NavPilotStackInspector<T: Hashable>: View {
    @ObservedObject private var pilot: NavPilot<T>

    internal init(_ pilot: NavPilot<T>) {
        self.pilot = pilot
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NavPilot Inspector")
                    .font(.headline)
                Spacer()
                Text("depth \(pilot.depth)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 8) {
                    ForEach(Array(pilot.stack.enumerated()), id: \.offset) { index, route in
                        Text("\(index): \(String(describing: route))")
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 120, alignment: .bottom)
        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .padding()
    }
}
