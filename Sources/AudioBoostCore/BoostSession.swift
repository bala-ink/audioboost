import AudioBoostDomain

struct BoostSession {
    let output: OutputDevice
    let process: AudioProcessRef
    let tap: TapHandle
    let aggregateDeviceID: UInt32
}
