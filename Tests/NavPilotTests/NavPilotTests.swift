import Testing
@testable import NavPilot

enum TestRoute: Hashable, Equatable {
    case home
    case detail(id: Int)
    case settings
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

    @Test func popToMissingRouteLeavesStackUnchanged() async throws {
        let pilot = NavPilot(initial: TestRoute.home)
        pilot.push(.detail(id: 1))
        let snapshot = pilot.stack

        pilot.popTo(.settings)

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
}
