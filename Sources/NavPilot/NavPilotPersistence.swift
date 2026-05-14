//
//  NavPilotPersistence.swift
//  NavPilot
//
//  Created by DK on 14/05/26.
//

import Foundation

@MainActor
internal enum NavPilotPersistence {
    internal static func defaultKey<T>(for type: T.Type, customKey: String? = nil) -> String {
        customKey ?? "NavPilot.\(String(reflecting: T.self)).stack"
    }

    internal static func loadStack<T: Codable>(forKey key: String, defaults: UserDefaults = .standard) -> [T]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([T].self, from: data)
    }

    internal static func saveStack<T: Codable>(_ stack: [T], forKey key: String, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(stack) else { return }

        if stack.isEmpty {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set(data, forKey: key)
        }
    }

    internal static func clear(forKey key: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
