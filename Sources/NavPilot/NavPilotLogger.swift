//
//  NavPilotLogger.swift
//  NavPilot
//
//  Created by DK on 14/05/26.
//

import Foundation
import OSLog

@MainActor
internal enum NavPilotLogger {
    private static let logger = Logger(subsystem: "NavPilot", category: "Navigation")
    private static var testSink: ((String) -> Void)?

    internal static func log(enabled: Bool, _ message: @autoclosure () -> String) {
        guard enabled else { return }
        let resolvedMessage = message()
        testSink?(resolvedMessage)
        logger.debug("\(resolvedMessage, privacy: .public)")
    }

    internal static func withTestSink<R>(
        _ sink: @escaping (String) -> Void,
        perform work: () throws -> R
    ) rethrows -> R {
        let previous = testSink
        testSink = sink

        defer {
            testSink = previous
        }

        return try work()
    }
}
