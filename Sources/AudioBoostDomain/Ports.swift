import Foundation

/// Abstraction over the audio plumbing so the coordinator can be tested without hardware.
public protocol CapabilityProbing: AnyObject {
    func evaluate() -> CapabilityReport
}

public protocol ProcessLocating: AnyObject {
    func currentProcess() throws -> AudioProcessRef
}

public protocol AudioTapProviding: AnyObject {
    func createTap(_ configuration: TapConfiguration) throws -> TapHandle
    func createAggregateDevice(_ descriptor: AggregateDeviceDescriptor) throws -> UInt32
    func destroyAggregateDevice(_ deviceID: UInt32)
    func destroyTap(_ handle: TapHandle)
}

public protocol DeviceObservation: AnyObject {
    func cancel()
}

public protocol OutputDeviceProviding: AnyObject {
    func defaultOutput() throws -> OutputDevice
    func observeChanges(_ handler: @escaping () -> Void) -> DeviceObservation
}

public protocol AudioGraphProviding: AnyObject {
    func build(_ plan: GraphPlan) throws
    func start() throws
    func stop()
    func apply(_ chain: ProcessingChain)
}

public enum LogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

public protocol BoostLogging: AnyObject {
    func log(level: LogLevel, _ message: String)
}
