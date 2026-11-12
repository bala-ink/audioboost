import Foundation

/// Pure state machine. Policy lives here; side effects are returned as `BoostEffect`
/// values and executed by the coordinator. This keeps every transition unit-testable.
public struct BoostStateMachine: Sendable {
    public private(set) var state: BoostState

    public init(initialState: BoostState = .idle) {
        self.state = initialState
    }

    @discardableResult
    public mutating func handle(_ event: BoostEvent) -> [BoostEffect] {
        let (nextState, effects) = Self.reduce(state: state, event: event)
        state = nextState
        return effects
    }

    public static func reduce(state: BoostState, event: BoostEvent) -> (BoostState, [BoostEffect]) {
        switch (state, event) {
        case (.unsupported, _):
            return (state, [])

        case (.idle, .startRequested):
            return (.preparing, [.createSession])

        case (.preparing, .sessionCreated):
            return (.running, [.applyConfiguration])

        case (.preparing, .sessionFailed(let error)):
            return (.failed(error), [.teardownSession])

        case (.preparing, .stopRequested):
            return (.stopping, [.teardownSession])

        case (.running, .stopRequested):
            return (.stopping, [.teardownSession])

        case (.running, .configurationChanged):
            return (.running, [.applyConfiguration])

        case (.running, .deviceChanged):
            return (.suspended, [.teardownSession, .notifyDeviceChanged])

        case (.running, .sessionFailed(let error)):
            return (.failed(error), [.teardownSession])

        case (.suspended, .startRequested):
            return (.preparing, [.createSession])

        case (.suspended, .stopRequested):
            return (.stopping, [.teardownSession])

        case (.stopping, .sessionTornDown):
            return (.idle, [])

        case (.failed, .startRequested):
            return (.preparing, [.createSession])

        case (.failed, .stopRequested), (.failed, .reset):
            return (.idle, [])

        case (.preparing, .deviceChanged),
            (.stopping, .deviceChanged),
            (.suspended, .deviceChanged),
            (.idle, .deviceChanged),
            (.failed, .deviceChanged):
            return (state, [])

        case (_, .configurationChanged):
            return (state, [])

        default:
            return (state, [])
        }
    }
}
