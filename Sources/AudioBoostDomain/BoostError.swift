import Foundation

public enum BoostError: Error, Equatable, Sendable {
    case unsupportedOperatingSystem(required: String)
    case permissionDenied
    case noOutputDevice
    case tapCreationFailed(status: Int32)
    case aggregateCreationFailed(status: Int32)
    case graphBuildFailed(reason: String)
    case engineStartFailed(reason: String)
    case deviceChanged
    case invariant(String)
}

extension BoostError {
    public var userMessage: String {
        switch self {
        case .unsupportedOperatingSystem(let required):
            return "Audio Boost requires \(required)."
        case .permissionDenied:
            return "Audio capture permission was denied."
        case .noOutputDevice:
            return "No audio output device is available."
        case .tapCreationFailed(let status):
            return "Could not start system audio capture (error \(status))."
        case .aggregateCreationFailed(let status):
            return "Could not create the audio routing device (error \(status))."
        case .graphBuildFailed(let reason):
            return "Could not build the audio graph: \(reason)."
        case .engineStartFailed(let reason):
            return "Could not start audio processing: \(reason)."
        case .deviceChanged:
            return "The audio output device changed."
        case .invariant(let message):
            return message
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unsupportedOperatingSystem:
            return "Update to macOS 14.2 (Sonoma) or later."
        case .permissionDenied, .tapCreationFailed:
            return
                "Open System Settings > Privacy & Security > Screen & System Audio Recording and allow AudioBoost, then try again."
        case .noOutputDevice:
            return "Connect an output device and set it as the system output."
        case .aggregateCreationFailed, .graphBuildFailed, .engineStartFailed:
            return "Stop and start Audio Boost again. If it keeps failing, file an issue."
        case .deviceChanged:
            return "Press Start to resume with the new output device."
        case .invariant:
            return nil
        }
    }

    public var isPermissionRelated: Bool {
        switch self {
        case .permissionDenied, .tapCreationFailed:
            return true
        default:
            return false
        }
    }
}
