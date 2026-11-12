import Testing

@testable import AudioBoostDomain

@Suite("Boost state machine")
struct BoostStateMachineTests {
    private let unsupportedReport = CapabilityReport(
        supportsProcessTap: false,
        hasOutputDevice: false,
        operatingSystemDescription: "test"
    )

    @Test("Idle -> preparing on start")
    func start() {
        expectTransition(from: .idle, event: .startRequested, to: .preparing, effects: [.createSession])
    }

    @Test("Preparing -> running after the session is created")
    func prepared() {
        expectTransition(from: .preparing, event: .sessionCreated, to: .running, effects: [.applyConfiguration])
    }

    @Test("Preparing -> failed when the session fails")
    func prepareFailed() {
        expectTransition(
            from: .preparing,
            event: .sessionFailed(.noOutputDevice),
            to: .failed(.noOutputDevice),
            effects: [.teardownSession]
        )
    }

    @Test("Preparing -> stopping on stop")
    func stopWhilePreparing() {
        expectTransition(from: .preparing, event: .stopRequested, to: .stopping, effects: [.teardownSession])
    }

    @Test("Running -> stopping on stop")
    func stopWhileRunning() {
        expectTransition(from: .running, event: .stopRequested, to: .stopping, effects: [.teardownSession])
    }

    @Test("Running applies configuration changes")
    func configurationChange() {
        expectTransition(
            from: .running,
            event: .configurationChanged,
            to: .running,
            effects: [.applyConfiguration]
        )
    }

    @Test("Running -> suspended when the output device changes")
    func deviceChanged() {
        expectTransition(
            from: .running,
            event: .deviceChanged,
            to: .suspended,
            effects: [.teardownSession, .notifyDeviceChanged]
        )
    }

    @Test("Running -> failed when the session fails")
    func runtimeFailure() {
        expectTransition(
            from: .running,
            event: .sessionFailed(.deviceChanged),
            to: .failed(.deviceChanged),
            effects: [.teardownSession]
        )
    }

    @Test("Suspended can restart or stop")
    func suspended() {
        expectTransition(from: .suspended, event: .startRequested, to: .preparing, effects: [.createSession])
        expectTransition(from: .suspended, event: .stopRequested, to: .stopping, effects: [.teardownSession])
    }

    @Test("Stopping -> idle after teardown completes")
    func tornDown() {
        expectTransition(from: .stopping, event: .sessionTornDown, to: .idle, effects: [])
    }

    @Test("Failed can retry or reset")
    func failed() {
        expectTransition(
            from: .failed(.noOutputDevice), event: .startRequested, to: .preparing, effects: [.createSession])
        expectTransition(from: .failed(.noOutputDevice), event: .stopRequested, to: .idle, effects: [])
        expectTransition(from: .failed(.noOutputDevice), event: .reset, to: .idle, effects: [])
    }

    @Test("Unsupported ignores every event")
    func unsupported() {
        let state = BoostState.unsupported(unsupportedReport)
        expectTransition(from: state, event: .startRequested, to: state, effects: [])
        expectTransition(from: state, event: .stopRequested, to: state, effects: [])
        expectTransition(from: state, event: .deviceChanged, to: state, effects: [])
    }

    @Test("Configuration changes are ignored while idle")
    func configurationWhileIdle() {
        expectTransition(from: .idle, event: .configurationChanged, to: .idle, effects: [])
    }

    @Test("Machine mutates its state and returns effects")
    func mutation() {
        var machine = BoostStateMachine()
        let effects = machine.handle(.startRequested)
        #expect(machine.state == .preparing)
        #expect(effects == [.createSession])
    }

    private func expectTransition(
        from state: BoostState,
        event: BoostEvent,
        to expectedState: BoostState,
        effects expectedEffects: [BoostEffect]
    ) {
        let (nextState, effects) = BoostStateMachine.reduce(state: state, event: event)
        #expect(nextState == expectedState)
        #expect(effects == expectedEffects)
    }
}
