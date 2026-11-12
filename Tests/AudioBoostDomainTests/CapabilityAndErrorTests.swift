import Testing

@testable import AudioBoostDomain

@Suite("Capability report")
struct CapabilityReportTests {
    @Test("Requires both tap support and an output device")
    func supported() {
        #expect(
            CapabilityReport(supportsProcessTap: true, hasOutputDevice: true, operatingSystemDescription: "x")
                .isSupported)
        #expect(
            !CapabilityReport(supportsProcessTap: false, hasOutputDevice: true, operatingSystemDescription: "x")
                .isSupported)
        #expect(
            !CapabilityReport(supportsProcessTap: true, hasOutputDevice: false, operatingSystemDescription: "x")
                .isSupported)
    }

    @Test("Reports the blocking error with the right precedence")
    func blockingError() {
        let unsupported = CapabilityReport(
            supportsProcessTap: false, hasOutputDevice: false, operatingSystemDescription: "x")
        #expect(unsupported.blockingError() == .unsupportedOperatingSystem(required: "macOS 14.2 or later"))

        let noOutput = CapabilityReport(
            supportsProcessTap: true, hasOutputDevice: false, operatingSystemDescription: "x")
        #expect(noOutput.blockingError() == .noOutputDevice)

        let supported = CapabilityReport(
            supportsProcessTap: true, hasOutputDevice: true, operatingSystemDescription: "x")
        #expect(supported.blockingError() == nil)
    }
}

@Suite("Boost errors")
struct BoostErrorTests {
    @Test("Permission-related errors are flagged")
    func permissionFlag() {
        #expect(BoostError.permissionDenied.isPermissionRelated)
        #expect(BoostError.tapCreationFailed(status: -1).isPermissionRelated)
        #expect(!BoostError.noOutputDevice.isPermissionRelated)
    }

    @Test("Every case has a user message")
    func messages() {
        let errors: [BoostError] = [
            .unsupportedOperatingSystem(required: "macOS 14.2"),
            .permissionDenied,
            .noOutputDevice,
            .tapCreationFailed(status: 1),
            .aggregateCreationFailed(status: 2),
            .graphBuildFailed(reason: "x"),
            .engineStartFailed(reason: "y"),
            .deviceChanged,
            .invariant("z"),
        ]
        for error in errors {
            #expect(!error.userMessage.isEmpty)
        }
    }
}
