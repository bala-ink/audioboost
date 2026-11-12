import Foundation

public enum BoostState: Equatable, Sendable {
    case unsupported(CapabilityReport)
    case idle
    case preparing
    case running
    case suspended
    case stopping
    case failed(BoostError)

    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    public var displayName: String {
        switch self {
        case .unsupported:
            return "Unsupported"
        case .idle:
            return "Idle"
        case .preparing:
            return "Starting…"
        case .running:
            return "Running"
        case .suspended:
            return "Output changed"
        case .stopping:
            return "Stopping…"
        case .failed:
            return "Error"
        }
    }
}

public enum BoostEvent: Equatable, Sendable {
    case startRequested
    case sessionCreated
    case sessionFailed(BoostError)
    case stopRequested
    case sessionTornDown
    case deviceChanged
    case configurationChanged
    case reset
}

public enum BoostEffect: Equatable, Sendable {
    case createSession
    case applyConfiguration
    case teardownSession
    case notifyDeviceChanged
}
