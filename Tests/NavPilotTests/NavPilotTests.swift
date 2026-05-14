import Foundation
import Testing
@testable import NavPilot

enum TestRoute: Hashable, Equatable {
    case home
    case detail(id: Int)
    case settings
}

struct DeepLinkProduct: Codable, Hashable, Equatable {
    let id: Int
    let name: String
}

enum DeepLinkRoute: Codable, Hashable, Equatable {
    case home
    case product(DeepLinkProduct)
    case checkout(items: [String])
}

@MainActor
@Suite("NavPilot")
struct NavPilotTests {
    @Test func initializesWithSingleRootRoute() async throws {
        let pilot = NavPilot(initial: TestRoute.home)

        #expect(pilot.stack == [.home])
        #expect(pilot.current == .home)
        #expect(pilot.depth == 1)
    }

    @Test func pushesRoutesInOrder() async throws {
        let pilot = NavPilot(initial: TestRoute.home)

        pilot.push(.detail(id: 1))
        pilot.push(.settings)

        #expect(pilot.stack == [.home, .detail(id: 1), .settings])
        #expect(pilot.current == .settings)
        #expect(pilot.depth == 3)
    }

    @Test func pushesMultipleRoutesInOneCall() async throws {
        let pilot = NavPilot(initial: TestRoute.home)

        pilot.push(.detail(id: 1), .settings)

        #expect(pilot.stack == [.home, .detail(id: 1), .settings])
    }

    @Test func popRemovesTopRouteButKeepsRoot() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1))

        pilot.pop()
        pilot.pop()

        #expect(pilot.stack == [.home])
        #expect(pilot.current == .home)
    }

    @Test func popCountClampsToRoot() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1), .settings)

        pilot.pop(count: 99)

        #expect(pilot.stack == [.home])
    }

    @Test func popToReturnsToFirstMatchingRoute() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1), .settings, .detail(id: 2))

        pilot.popTo(.detail(id: 1))

        #expect(pilot.stack == [.home, .detail(id: 1)])
        #expect(pilot.current == .detail(id: 1))
    }

    @Test func popToLastReturnsToMostRecentMatchingRoute() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1), .settings, .detail(id: 1), .detail(id: 2))

        pilot.popToLast(.detail(id: 1))

        #expect(pilot.stack == [.home, .detail(id: 1), .settings, .detail(id: 1)])
        #expect(pilot.current == .detail(id: 1))
    }

    @Test func popToMissingRouteLeavesStackUnchanged() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1))
        let snapshot = pilot.stack

        pilot.popTo(.settings)

        #expect(pilot.stack == snapshot)
    }

    @Test func popToLastMissingRouteLeavesStackUnchanged() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1))
        let snapshot = pilot.stack

        pilot.popToLast(.settings)

        #expect(pilot.stack == snapshot)
    }

    @Test func popToRootLeavesOnlyTheRoot() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1), .settings)

        pilot.popToRoot()

        #expect(pilot.stack == [.home])
    }

    @Test func replaceSwapsTheWholeStack() async throws {
        let pilot = NavPilot(initial: TestRoute.home)

        pilot.replace([.settings, .detail(id: 7)])

        #expect(pilot.stack == [.settings, .detail(id: 7)])
        #expect(pilot.current == .detail(id: 7))
    }

    @Test func replaceEmptyArrayIsIgnored() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1))

        pilot.replace([])

        #expect(pilot.stack == [.home, .detail(id: 1)])
    }

    @Test func replaceCurrentOnlyTouchesTheTopRoute() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1))

        pilot.replaceCurrent(with: .settings)

        #expect(pilot.stack == [.home, .settings])
    }

    @Test func syncTailPreservesRootAndUpdatesPath() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1), .settings)

        pilot.syncTail([.detail(id: 42)])

        #expect(pilot.stack == [.home, .detail(id: 42)])
        #expect(pilot.current == .detail(id: 42))
    }

    @Test func emitsDebugLogsForNavigationActions() async throws {
        var messages: [String] = []
        NavPilotLogger.withTestSink({ messages.append($0) }) {
            let pilot = NavPilot(initial: TestRoute.home, debug: true)

            pilot.push(.detail(id: 1))
            pilot.pop()
            pilot.replaceCurrent(with: .settings)
        }

        #expect(messages == [
            "init [home]",
            "push detail(id: 1) -> [home -> detail(id: 1)]",
            "pop -> [home]",
            "replaceCurrent settings -> [settings]"
        ])
    }

    @Test func emitsDebugLogsForNoopActions() async throws {
        var messages: [String] = []
        NavPilotLogger.withTestSink({ messages.append($0) }) {
            let pilot = NavPilot(initial: TestRoute.home, debug: true)

            pilot.pop()
            pilot.popTo(.settings)
            pilot.replace([])
        }

        #expect(messages == [
            "init [home]",
            "pop ignored at root -> [home]",
            "popTo settings ignored (not found) -> [home]",
            "replace ignored: [] -> [home]"
        ])
    }

    @Test func staysSilentByDefault() async throws {
        var messages: [String] = []
        NavPilotLogger.withTestSink({ messages.append($0) }) {
            let pilot = NavPilot(initial: TestRoute.home)
            pilot.push(.detail(id: 1))
            pilot.pop()
        }

        #expect(messages.isEmpty)
    }

    @Test func encodesAndDecodesDeepLinks() async throws {
        let pilot = NavPilot<DeepLinkRoute>(initial: .home)
        pilot.push(.product(DeepLinkProduct(id: 1, name: "Keyboard")))
        pilot.push(.checkout(items: ["Keyboard"]))

        let url = pilot.deepLinkURL()
        #expect(url?.scheme == "navpilot")

        let restored = NavPilot<DeepLinkRoute>(initial: .home)
        let handled = restored.handleDeepLink(url!)

        #expect(handled)
        #expect(restored.stack == [
            .home,
            .product(DeepLinkProduct(id: 1, name: "Keyboard")),
            .checkout(items: ["Keyboard"])
        ])
    }

    @Test func rejectsInvalidDeepLinks() async throws {
        let pilot = NavPilot<DeepLinkRoute>(initial: .home)
        let snapshot = pilot.stack

        let handled = pilot.handleDeepLink(URL(string: "https://example.com/invalid")!)

        #expect(!handled)
        #expect(pilot.stack == snapshot)
    }
}
