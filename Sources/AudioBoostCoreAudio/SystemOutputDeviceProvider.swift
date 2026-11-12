import AudioBoostDomain
import CoreAudio
import Foundation

public final class SystemOutputDeviceProvider: OutputDeviceProviding {
    public init() {}

    public func defaultOutput() throws -> OutputDevice {
        guard let deviceID = defaultOutputDeviceID() else {
            throw BoostError.noOutputDevice
        }
        guard let uid = stringProperty(deviceID, kAudioDevicePropertyDeviceUID), !uid.isEmpty else {
            throw BoostError.noOutputDevice
        }

        let name = stringProperty(deviceID, kAudioDevicePropertyDeviceNameCFString) ?? "Output"
        let sampleRate = nominalSampleRate(deviceID) ?? 48_000
        let channels = outputChannelCount(deviceID) ?? 2

        return OutputDevice(
            identifier: deviceID,
            uid: uid,
            name: name,
            streamIndex: 0,
            format: AudioFormatDescriptor(sampleRate: sampleRate, channelCount: channels)
        )
    }

    public func observeChanges(_ handler: @escaping () -> Void) -> DeviceObservation {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let listener: AudioObjectPropertyListenerBlock = { _, _ in
            handler()
        }
        let queue = DispatchQueue.main
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            queue,
            listener
        )

        guard status == noErr else {
            return SystemDeviceObservation {}
        }

        return SystemDeviceObservation {
            var addressCopy = address
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &addressCopy,
                queue,
                listener
            )
        }
    }

    private func defaultOutputDeviceID() -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }
        return deviceID
    }

    private func stringProperty(_ deviceID: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        guard status == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    private func nominalSampleRate(_ deviceID: AudioObjectID) -> Double? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var rate: Float64 = 0
        var size = UInt32(MemoryLayout<Float64>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &rate)
        guard status == noErr, rate > 0 else { return nil }
        return rate
    }

    private func outputChannelCount(_ deviceID: AudioObjectID) -> Int? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamFormat,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var streamFormat = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &streamFormat)
        guard status == noErr, streamFormat.mChannelsPerFrame > 0 else { return nil }
        return Int(streamFormat.mChannelsPerFrame)
    }
}

private final class SystemDeviceObservation: DeviceObservation {
    private var cancelHandler: (() -> Void)?

    init(_ cancel: @escaping () -> Void) {
        self.cancelHandler = cancel
    }

    func cancel() {
        cancelHandler?()
        cancelHandler = nil
    }

    deinit {
        cancel()
    }
}
