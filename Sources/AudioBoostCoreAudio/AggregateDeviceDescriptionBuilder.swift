import AudioBoostDomain
import CoreAudio
import Foundation

/// Translates the framework-free `AggregateDeviceDescriptor` into the CFDictionary
/// shape expected by `AudioHardwareCreateAggregateDevice`.
public enum AggregateDeviceDescriptionBuilder {
    public static func dictionary(from descriptor: AggregateDeviceDescriptor) -> [String: Any] {
        var tapEntry: [String: Any] = [kAudioSubTapUIDKey: descriptor.tapUID]
        if descriptor.driftCompensation {
            tapEntry[kAudioSubTapDriftCompensationKey] = true
        }

        let subDevice: [String: Any] = [kAudioSubDeviceUIDKey: descriptor.outputDeviceUID]

        return [
            kAudioAggregateDeviceNameKey: descriptor.name,
            kAudioAggregateDeviceUIDKey: descriptor.uid,
            kAudioAggregateDeviceMainSubDeviceKey: descriptor.outputDeviceUID,
            kAudioAggregateDeviceIsPrivateKey: descriptor.isPrivate,
            kAudioAggregateDeviceIsStackedKey: descriptor.isStacked,
            kAudioAggregateDeviceTapAutoStartKey: descriptor.tapAutoStart,
            kAudioAggregateDeviceSubDeviceListKey: [subDevice],
            kAudioAggregateDeviceTapListKey: [tapEntry],
        ]
    }
}
