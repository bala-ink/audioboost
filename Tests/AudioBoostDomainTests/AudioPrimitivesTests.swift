import Testing

@testable import AudioBoostDomain

@Suite("Tap configuration factory")
struct TapConfigurationFactoryTests {
    @Test("Builds a private muted system-wide tap that excludes our process")
    func systemWide() {
        let process = AudioProcessRef(objectID: 42)
        let output = OutputDevice(identifier: 1, uid: "device-uid", name: "Speakers", streamIndex: 3)
        let configuration = TapConfigurationFactory.systemWide(excluding: process, output: output)

        #expect(configuration.isPrivate)
        #expect(configuration.muteBehavior == .mutedWhenTapped)
        #expect(configuration.excludedProcessIDs == [42])
        #expect(configuration.deviceUID == "device-uid")
        #expect(configuration.streamIndex == 3)
        #expect(configuration.name == "AudioBoost Tap")
    }
}

@Suite("Aggregate device factory")
struct AggregateDeviceFactoryTests {
    @Test("Uses the tap and output identifiers")
    func make() {
        let tap = TapHandle(objectID: 7, uid: "tap-uid")
        let output = OutputDevice(identifier: 1, uid: "out-uid", name: "Speakers")
        let descriptor = AggregateDeviceFactory.make(tap: tap, output: output, uid: "aggregate-uid")

        #expect(descriptor.uid == "aggregate-uid")
        #expect(descriptor.tapUID == "tap-uid")
        #expect(descriptor.outputDeviceUID == "out-uid")
        #expect(descriptor.isPrivate)
        #expect(descriptor.isStacked == false)
        #expect(descriptor.tapAutoStart)
        #expect(descriptor.driftCompensation)
    }

    @Test("Generates unique aggregate identifiers")
    func uniqueIdentifiers() {
        let tap = TapHandle(objectID: 7, uid: "tap-uid")
        let output = OutputDevice(identifier: 1, uid: "out-uid", name: "Speakers")
        let first = AggregateDeviceFactory.make(tap: tap, output: output)
        let second = AggregateDeviceFactory.make(tap: tap, output: output)
        #expect(first.uid != second.uid)
        #expect(first.uid.count == 36)
    }
}

@Suite("Audio format descriptor")
struct AudioFormatDescriptorTests {
    @Test("Falls back to sane values")
    func fallback() {
        let descriptor = AudioFormatDescriptor(sampleRate: 0, channelCount: 0)
        #expect(descriptor.sampleRate == 48_000)
        #expect(descriptor.channelCount == 1)
    }
}
