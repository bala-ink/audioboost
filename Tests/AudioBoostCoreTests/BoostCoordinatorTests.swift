import AudioBoostDomain
import Testing

@testable import AudioBoostCore

@Suite("Boost coordinator")
@MainActor
struct BoostCoordinatorTests {
    @Test("Starts idle when the system is supported")
    func startsIdle() {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()
        #expect(coordinator.state == .idle)
        #expect(fakes.outputs.observeCount == 1)
    }

    @Test("Reports unsupported systems and ignores start")
    func unsupported() {
        let fakes = Fakes()
        fakes.capabilities.report = CapabilityReport(
            supportsProcessTap: false,
            hasOutputDevice: true,
            operatingSystemDescription: "old"
        )
        let coordinator = fakes.makeCoordinator()

        guard case .unsupported = coordinator.state else {
            Issue.record("Expected unsupported state")
            return
        }

        coordinator.start()
        #expect(fakes.taps.createTapCount == 0)
    }

    @Test("Happy path wires tap, aggregate, graph and configuration")
    func happyPath() {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()

        coordinator.start()

        #expect(coordinator.state == .running)
        #expect(fakes.taps.createTapCount == 1)
        #expect(fakes.taps.createAggregateCount == 1)
        #expect(fakes.graph.buildCount == 1)
        #expect(fakes.graph.startCount == 1)
        #expect(fakes.graph.appliedChains.last == coordinator.configuration.processingChain)

        let tapConfiguration = fakes.taps.lastTapConfiguration
        #expect(tapConfiguration?.muteBehavior == .mutedWhenTapped)
        #expect(tapConfiguration?.isPrivate == true)
        #expect(tapConfiguration?.excludedProcessIDs == [99])
        #expect(tapConfiguration?.deviceUID == "out-uid")
    }

    @Test("Missing output device fails cleanly")
    func noOutputDevice() {
        let fakes = Fakes()
        fakes.outputs.error = .noOutputDevice
        let coordinator = fakes.makeCoordinator()

        coordinator.start()

        #expect(coordinator.state == .failed(.noOutputDevice))
        #expect(fakes.taps.createTapCount == 0)
    }

    @Test("Tap failure is reported without creating an aggregate")
    func tapFailure() {
        let fakes = Fakes()
        fakes.taps.tapError = .tapCreationFailed(status: -1)
        let coordinator = fakes.makeCoordinator()

        coordinator.start()

        #expect(coordinator.state == .failed(.tapCreationFailed(status: -1)))
        #expect(fakes.taps.createAggregateCount == 0)
        #expect(fakes.graph.stopCount >= 1)
    }

    @Test("Aggregate failure destroys the tap")
    func aggregateFailure() {
        let fakes = Fakes()
        fakes.taps.aggregateError = .aggregateCreationFailed(status: -2)
        let coordinator = fakes.makeCoordinator()

        coordinator.start()

        #expect(coordinator.state == .failed(.aggregateCreationFailed(status: -2)))
        #expect(fakes.taps.destroyedTaps.count == 1)
        #expect(fakes.taps.destroyedAggregates.isEmpty)
    }

    @Test("Graph build failure cleans up aggregate and tap")
    func graphBuildFailure() {
        let fakes = Fakes()
        fakes.graph.buildError = .graphBuildFailed(reason: "boom")
        let coordinator = fakes.makeCoordinator()

        coordinator.start()

        #expect(coordinator.state == .failed(.graphBuildFailed(reason: "boom")))
        #expect(fakes.taps.destroyedAggregates == [501])
        #expect(fakes.taps.destroyedTaps.count == 1)
    }

    @Test("Graph start failure cleans up resources")
    func graphStartFailure() {
        let fakes = Fakes()
        fakes.graph.startError = .engineStartFailed(reason: "nope")
        let coordinator = fakes.makeCoordinator()

        coordinator.start()

        #expect(coordinator.state == .failed(.engineStartFailed(reason: "nope")))
        #expect(fakes.taps.destroyedAggregates == [501])
        #expect(fakes.taps.destroyedTaps.count == 1)
        #expect(fakes.graph.stopCount >= 1)
    }

    @Test("Stop tears everything down and returns to idle")
    func stop() {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()

        coordinator.start()
        coordinator.stop()

        #expect(coordinator.state == .idle)
        #expect(fakes.taps.destroyedAggregates == [501])
        #expect(fakes.taps.destroyedTaps.count == 1)
    }

    @Test("Gain changes while running reapply without rebuilding")
    func gainWhileRunning() {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()

        coordinator.start()
        let appliedBefore = fakes.graph.appliedChains.count

        coordinator.setGain(6)

        #expect(coordinator.configuration.gainDecibels == 6)
        #expect(fakes.graph.appliedChains.count == appliedBefore + 1)
        #expect(fakes.taps.createTapCount == 1)
        #expect(fakes.graph.buildCount == 1)
    }

    @Test("Gain changes while idle are stored but not applied")
    func gainWhileIdle() {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()

        coordinator.setGain(6)

        #expect(coordinator.configuration.gainDecibels == 6)
        #expect(fakes.graph.appliedChains.isEmpty)
    }

    @Test("Toggling the compressor re-applies the chain")
    func compressorToggle() {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()
        coordinator.start()

        coordinator.setCompressorEnabled(false)

        #expect(coordinator.configuration.compressorEnabled == false)
        guard let chain = fakes.graph.appliedChains.last else {
            Issue.record("Expected an applied chain")
            return
        }
        let hasDisabledCompressor = chain.nodes.contains { node in
            if case .compressor(let configuration) = node { return configuration.isEnabled == false }
            return false
        }
        #expect(hasDisabledCompressor)
    }

    @Test("Retry after a failure starts a new session")
    func retry() {
        let fakes = Fakes()
        fakes.taps.tapError = .tapCreationFailed(status: -1)
        let coordinator = fakes.makeCoordinator()

        coordinator.start()
        #expect(coordinator.state == .failed(.tapCreationFailed(status: -1)))

        fakes.taps.tapError = nil
        coordinator.start()

        #expect(coordinator.state == .running)
        #expect(fakes.taps.createTapCount == 2)
    }

    @Test("Device changes suspend the running session")
    func deviceChange() async throws {
        let fakes = Fakes()
        let coordinator = fakes.makeCoordinator()
        coordinator.start()

        fakes.outputs.triggerChange()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(coordinator.state == .suspended)
        #expect(fakes.taps.destroyedAggregates == [501])
        #expect(fakes.graph.stopCount >= 1)

        coordinator.start()
        #expect(coordinator.state == .running)
    }
}
