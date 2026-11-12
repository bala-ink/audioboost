import Foundation

public struct CapabilityReport: Equatable, Sendable {
    public var supportsProcessTap: Bool
    public var hasOutputDevice: Bool
    public var operatingSystemDescription: String

    public init(supportsProcessTap: Bool, hasOutputDevice: Bool, operatingSystemDescription: String) {
        self.supportsProcessTap = supportsProcessTap
        self.hasOutputDevice = hasOutputDevice
        self.operatingSystemDescription = operatingSystemDescription
    }

    public var isSupported: Bool {
        supportsProcessTap && hasOutputDevice
    }

    public func blockingError() -> BoostError? {
        if !supportsProcessTap {
            return .unsupportedOperatingSystem(required: "macOS 14.2 or later")
        }
        if !hasOutputDevice {
            return .noOutputDevice
        }
        return nil
    }
}
