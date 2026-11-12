import AudioBoostDomain
import Foundation

public final class SystemCapabilityProbe: CapabilityProbing {
    private let outputProvider: OutputDeviceProviding

    public init(outputProvider: OutputDeviceProviding = SystemOutputDeviceProvider()) {
        self.outputProvider = outputProvider
    }

    public func evaluate() -> CapabilityReport {
        let supportsProcessTap: Bool
        if #available(macOS 14.2, *) {
            supportsProcessTap = true
        } else {
            supportsProcessTap = false
        }

        let hasOutput = (try? outputProvider.defaultOutput()) != nil

        return CapabilityReport(
            supportsProcessTap: supportsProcessTap,
            hasOutputDevice: hasOutput,
            operatingSystemDescription: ProcessInfo.processInfo.operatingSystemVersionString
        )
    }
}
