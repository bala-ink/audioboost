import AudioBoostDomain
import CoreAudio
import Testing

@testable import AudioBoostCoreAudio

@Suite("Aggregate device description")
struct AggregateDeviceDescriptionBuilderTests {
    private func makeDescriptor(driftCompensation: Bool = true) -> AggregateDeviceDescriptor {
        AggregateDeviceDescriptor(
            name: "Boost",
            uid: "aggregate-uid",
            isPrivate: true,
            isStacked: false,
            tapUID: "tap-uid",
            outputDeviceUID: "output-uid",
            tapAutoStart: true,
            driftCompensation: driftCompensation
        )
    }

    @Test("Produces the dictionary expected by Core Audio")
    func dictionary() {
        let dictionary = AggregateDeviceDescriptionBuilder.dictionary(from: makeDescriptor())

        #expect(dictionary[kAudioAggregateDeviceNameKey] as? String == "Boost")
        #expect(dictionary[kAudioAggregateDeviceUIDKey] as? String == "aggregate-uid")
        #expect(dictionary[kAudioAggregateDeviceMainSubDeviceKey] as? String == "output-uid")
        #expect(dictionary[kAudioAggregateDeviceIsPrivateKey] as? Bool == true)
        #expect(dictionary[kAudioAggregateDeviceIsStackedKey] as? Bool == false)
        #expect(dictionary[kAudioAggregateDeviceTapAutoStartKey] as? Bool == true)

        let subDevices = dictionary[kAudioAggregateDeviceSubDeviceListKey] as? [[String: Any]]
        #expect(subDevices?.count == 1)
        #expect(subDevices?.first?[kAudioSubDeviceUIDKey] as? String == "output-uid")

        let taps = dictionary[kAudioAggregateDeviceTapListKey] as? [[String: Any]]
        #expect(taps?.count == 1)
        #expect(taps?.first?[kAudioSubTapUIDKey] as? String == "tap-uid")
        #expect(taps?.first?[kAudioSubTapDriftCompensationKey] as? Bool == true)
    }

    @Test("Omits drift compensation when disabled")
    func withoutDriftCompensation() {
        let dictionary = AggregateDeviceDescriptionBuilder.dictionary(from: makeDescriptor(driftCompensation: false))
        let taps = dictionary[kAudioAggregateDeviceTapListKey] as? [[String: Any]]
        #expect(taps?.first?[kAudioSubTapDriftCompensationKey] == nil)
    }
}
