import AudioBoostCore
import AudioBoostDomain
import Foundation

final class FakeCapabilities: CapabilityProbing {
    var report = CapabilityReport(
        supportsProcessTap: true,
        hasOutputDevice: true,
        operatingSystemDescription: "test"
    )

    func evaluate() -> CapabilityReport {
        report
    }
}

final class FakeProcesses: ProcessLocating {
    var error: BoostError?
    var process = AudioProcessRef(objectID: 99)

    func currentProcess() throws -> AudioProcessRef {
        if let error { throw error }
        return process
    }
}

final class FakeTaps: AudioTapProviding {
    var tapError: BoostError?
    var aggregateError: BoostError?

    private(set) var createTapCount = 0
    private(set) var createAggregateCount = 0
    private(set) var destroyedTaps: [TapHandle] = []
    private(set) var destroyedAggregates: [UInt32] = []
    private(set) var lastTapConfiguration: TapConfiguration?
    private(set) var lastAggregateDescriptor: AggregateDeviceDescriptor?

    func createTap(_ configuration: TapConfiguration) throws -> TapHandle {
        createTapCount += 1
        lastTapConfiguration = configuration
        if let tapError { throw tapError }
        return TapHandle(objectID: 100 + UInt32(createTapCount), uid: "tap-\(createTapCount)")
    }

    func createAggregateDevice(_ descriptor: AggregateDeviceDescriptor) throws -> UInt32 {
        createAggregateCount += 1
        lastAggregateDescriptor = descriptor
        if let aggregateError { throw aggregateError }
        return 500 + UInt32(createAggregateCount)
    }

    func destroyAggregateDevice(_ deviceID: UInt32) {
        destroyedAggregates.append(deviceID)
    }

    func destroyTap(_ handle: TapHandle) {
        destroyedTaps.append(handle)
    }
}

final class FakeDeviceObservation: DeviceObservation {
    private(set) var cancelled = false

    func cancel() {
        cancelled = true
    }
}

final class FakeOutputs: OutputDeviceProviding {
    var output: OutputDevice? = OutputDevice(identifier: 1, uid: "out-uid", name: "Fake Output")
    var error: BoostError?

    private(set) var observeCount = 0
    private var handler: (() -> Void)?
    private(set) var observation = FakeDeviceObservation()

    func defaultOutput() throws -> OutputDevice {
        if let error { throw error }
        guard let output else { throw BoostError.noOutputDevice }
        return output
    }

    func observeChanges(_ handler: @escaping () -> Void) -> DeviceObservation {
        observeCount += 1
        self.handler = handler
        return observation
    }

    func triggerChange() {
        handler?()
    }
}

final class FakeGraph: AudioGraphProviding {
    var buildError: BoostError?
    var startError: BoostError?

    private(set) var buildCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var appliedChains: [ProcessingChain] = []
    private(set) var lastPlan: GraphPlan?

    func build(_ plan: GraphPlan) throws {
        buildCount += 1
        lastPlan = plan
        if let buildError { throw buildError }
    }

    func start() throws {
        startCount += 1
        if let startError { throw startError }
    }

    func stop() {
        stopCount += 1
    }

    func apply(_ chain: ProcessingChain) {
        appliedChains.append(chain)
    }
}

final class FakeLogger: BoostLogging {
    private(set) var entries: [(LogLevel, String)] = []

    func log(level: LogLevel, _ message: String) {
        entries.append((level, message))
    }
}

@MainActor
final class Fakes {
    let capabilities = FakeCapabilities()
    let processes = FakeProcesses()
    let taps = FakeTaps()
    let outputs = FakeOutputs()
    let graph = FakeGraph()
    let logger = FakeLogger()

    func makeCoordinator(
        configuration: BoostConfiguration = BoostConfiguration()
    ) -> BoostCoordinator {
        BoostCoordinator(
            capabilities: capabilities,
            processes: processes,
            taps: taps,
            outputs: outputs,
            graph: graph,
            logger: logger,
            initialConfiguration: configuration
        )
    }
}
