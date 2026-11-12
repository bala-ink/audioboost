import AudioBoostDomain
import Foundation

public enum BoostFormatting {
    public static func gainLabel(_ decibels: Float) -> String {
        let rounded = Int(decibels.rounded())
        return rounded >= 0 ? "+\(rounded) dB" : "\(rounded) dB"
    }

    public static func statusLabel(for state: BoostState) -> String {
        switch state {
        case .failed(let error):
            return error.userMessage
        case .unsupported(let report):
            return report.blockingError()?.userMessage ?? "Unsupported"
        default:
            return state.displayName
        }
    }

    public static func recoverySuggestion(for state: BoostState) -> String? {
        if case .failed(let error) = state {
            return error.recoverySuggestion
        }
        if case .unsupported(let report) = state {
            return report.blockingError()?.recoverySuggestion
        }
        return nil
    }

    public static func isStartEnabled(for state: BoostState) -> Bool {
        switch state {
        case .idle, .suspended, .failed:
            return true
        case .preparing, .running, .unsupported, .stopping:
            return false
        }
    }
}
