import AudioBoostDomain
import CoreAudio
import Foundation

public final class SystemProcessLocator: ProcessLocating {
    public init() {}

    public func currentProcess() throws -> AudioProcessRef {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var pid = pid_t(getpid())
        var objectID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(MemoryLayout<pid_t>.size),
            &pid,
            &size,
            &objectID
        )

        guard status == noErr, objectID != kAudioObjectUnknown else {
            throw BoostError.invariant("Could not resolve this process to an audio object (error \(status)).")
        }

        return AudioProcessRef(objectID: objectID)
    }
}
