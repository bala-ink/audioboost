import AudioBoostDomain
import Foundation
import Testing

@testable import AudioBoostCoreAudio

/// Opt-in hardware test. Run with:
/// `AUDIOBOOST_INTEGRATION=1 swift test --filter Integration`
@Suite("Integration (real Core Audio)")
struct IntegrationTests {
    @Test(
        "Creates and destroys a real tap and aggregate device",
        .enabled(if: ProcessInfo.processInfo.environment["AUDIOBOOST_INTEGRATION"] == "1")
    )
    func tapLifecycle() throws {
        let controller = CoreAudioTapController()
        let output = try SystemOutputDeviceProvider().defaultOutput()
        let process = try SystemProcessLocator().currentProcess()
        let configuration = TapConfigurationFactory.systemWide(excluding: process, output: output)

        let tap = try controller.createTap(configuration)
        let descriptor = AggregateDeviceFactory.make(tap: tap, output: output)
        let aggregate = try controller.createAggregateDevice(descriptor)

        #expect(aggregate != 0)

        controller.destroyAggregateDevice(aggregate)
        controller.destroyTap(tap)
    }
}
