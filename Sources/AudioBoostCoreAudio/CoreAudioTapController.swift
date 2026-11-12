import AudioBoostDomain
import CoreAudio
import Foundation

public final class CoreAudioTapController: AudioTapProviding {
    public init() {}

    public func createTap(_ configuration: TapConfiguration) throws -> TapHandle {
        guard #available(macOS 14.2, *) else {
            throw BoostError.unsupportedOperatingSystem(required: "macOS 14.2 or later")
        }

        let description = CATapDescription(
            __excludingProcesses: configuration.excludedProcessIDs.map { NSNumber(value: $0) },
            andDeviceUID: configuration.deviceUID,
            withStream: configuration.streamIndex
        )

        let uuid = UUID()
        description.uuid = uuid
        description.name = configuration.name
        description.isPrivate = configuration.isPrivate
        description.isMono = false
        description.isMixdown = true

        switch configuration.muteBehavior {
        case .unmuted:
            description.muteBehavior = .unmuted
        case .muted:
            description.muteBehavior = .muted
        case .mutedWhenTapped:
            description.muteBehavior = .mutedWhenTapped
        }

        var tapID = AudioObjectID(kAudioObjectUnknown)
        let status = AudioHardwareCreateProcessTap(description, &tapID)
        guard status == noErr, tapID != kAudioObjectUnknown else {
            throw BoostError.tapCreationFailed(status: status)
        }

        return TapHandle(objectID: tapID, uid: uuid.uuidString)
    }

    public func createAggregateDevice(_ descriptor: AggregateDeviceDescriptor) throws -> UInt32 {
        guard #available(macOS 14.2, *) else {
            throw BoostError.unsupportedOperatingSystem(required: "macOS 14.2 or later")
        }

        let dictionary = AggregateDeviceDescriptionBuilder.dictionary(from: descriptor)
        var aggregateDeviceID = AudioObjectID(kAudioObjectUnknown)
        let status = AudioHardwareCreateAggregateDevice(dictionary as CFDictionary, &aggregateDeviceID)
        guard status == noErr, aggregateDeviceID != kAudioObjectUnknown else {
            throw BoostError.aggregateCreationFailed(status: status)
        }
        return aggregateDeviceID
    }

    public func destroyAggregateDevice(_ deviceID: UInt32) {
        guard deviceID != kAudioObjectUnknown else { return }
        AudioHardwareDestroyAggregateDevice(deviceID)
    }

    public func destroyTap(_ handle: TapHandle) {
        guard #available(macOS 14.2, *) else { return }
        guard handle.objectID != kAudioObjectUnknown else { return }
        AudioHardwareDestroyProcessTap(handle.objectID)
    }
}
