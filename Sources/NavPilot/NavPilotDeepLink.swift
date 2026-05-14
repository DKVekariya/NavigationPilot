//
//  NavPilotDeepLink.swift
//  NavPilot
//
//  Created by DK on 14/05/26.
//

import Foundation

internal enum NavPilotDeepLinkCodec {
    private static let scheme = "navpilot"
    private static let host = "stack"
    private static let payloadKey = "payload"

    internal static func makeURL<T: Codable>(from stack: [T], scheme: String = scheme, host: String = host) -> URL? {
        guard !stack.isEmpty else { return nil }

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(stack) else { return nil }
        let payload = data.base64URLEncodedString()

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: payloadKey, value: payload)]
        return components.url
    }

    internal static func decode<T: Codable>(_ url: URL, expectedScheme: String = scheme, expectedHost: String = host) -> [T]? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        guard components.scheme == expectedScheme else { return nil }
        guard components.host == expectedHost else { return nil }
        guard let payload = components.queryItems?.first(where: { $0.name == payloadKey })?.value else { return nil }
        guard let data = Data(base64URLEncoded: payload) else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode([T].self, from: data)
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var padded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = padded.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: padded) else { return nil }
        self = data
    }
}

