import AudioBoostDomain
import Combine
import Foundation

/// Drives the boost lifecycle. Owns no audio APIs directly; everything goes through
/// the domain ports, which makes this class fully testable with fakes.
@MainActor
public final class BoostCoordinator: ObservableObject {
    @Published public private(set) var state: BoostState
    @Published public private(set) var configuration: BoostConfiguration

    private var stateMachine: BoostStateMachine
    private let capabilities: CapabilityProbing
    private let processes: ProcessLocating
    private let taps: AudioTapProviding
    private let outputs: OutputDeviceProviding
    private let graph: AudioGraphProviding
    private let logger: BoostLogging

    private var session: BoostSession?
    private var observation: DeviceObservation?

    public init(
        capabilities: CapabilityProbing,
        processes: ProcessLocating,
        taps: AudioTapProviding,
        outputs: OutputDeviceProviding,
        graph: AudioGraphProviding,
        logger: BoostLogging,
        initialConfiguration: BoostConfiguration = BoostConfiguration()
    ) {
        self.capabilities = capabilities
        self.processes = processes
        self.taps = taps
        self.outputs = outputs
        self.graph = graph
        self.logger = logger
        self.configuration = initialConfiguration

        let report = capabilities.evaluate()
        let initialState: BoostState = report.isSupported ? .idle : .unsupported(report)
        self.state = initialState
        self.stateMachine = BoostStateMachine(initialState: initialState)

        self.observation = outputs.observeChanges { [weak self] in
            Task { @MainActor in
                self?.dispatch(.deviceChanged)
            }
        }

        logger.log(level: .info, "Initialized in state \(initialState.displayName)")
    }

    deinit {
        observation?.cancel()
    }

    public var isRunning: Bool {
        state.isRunning
    }

    public var capabilityReport: CapabilityReport? {
        if case .unsupported(let report) = state { return report }
        return nil
    }

    public func start() {
        dispatch(.startRequested)
    }

    public func stop() {
        dispatch(.stopRequested)
    }

    public func retry() {
        dispatch(.startRequested)
    }

    public func setGain(_ decibels: Float) {
        configuration.setGain(decibels)
        dispatch(.configurationChanged)
    }

    public func setCompressorEnabled(_ enabled: Bool) {
        guard configuration.compressorEnabled != enabled else { return }
        configuration.compressorEnabled = enabled
        dispatch(.configurationChanged)
    }

    public func setLimiterEnabled(_ enabled: Bool) {
        guard configuration.limiterEnabled != enabled else { return }
        configuration.limiterEnabled = enabled
        dispatch(.configurationChanged)
    }

    private func dispatch(_ event: BoostEvent) {
        let effects = stateMachine.handle(event)
        state = stateMachine.state
        logger.log(level: .debug, "event=\(event) state=\(state.displayName)")
        for effect in effects {
            execute(effect)
        }
    }

    private func execute(_ effect: BoostEffect) {
        switch effect {
        case .createSession:
            createSession()
        case .applyConfiguration:
            applyConfiguration()
        case .teardownSession:
            teardownSession()
        case .notifyDeviceChanged:
            logger.log(level: .info, "Audio output device changed; boost suspended")
        }
    }

    private func createSession() {
        let report = capabilities.evaluate()
        if let error = report.blockingError() {
            dispatch(.sessionFailed(error))
            return
        }

        var createdTap: TapHandle?
        var createdAggregate: UInt32?

        do {
            let process = try processes.currentProcess()
            let output = try outputs.defaultOutput()
            let tapConfiguration = TapConfigurationFactory.systemWide(excluding: process, output: output)
            let tap = try taps.createTap(tapConfiguration)
            createdTap = tap

            let descriptor = AggregateDeviceFactory.make(tap: tap, output: output)
            let aggregateDeviceID = try taps.createAggregateDevice(descriptor)
            createdAggregate = aggregateDeviceID

            let plan = GraphPlan(
                aggregateDeviceID: aggregateDeviceID,
                outputDevice: output,
                chain: configuration.processingChain
            )
            try graph.build(plan)
            try graph.start()

            session = BoostSession(
                output: output,
                process: process,
                tap: tap,
                aggregateDeviceID: aggregateDeviceID
            )
            logger.log(level: .info, "Boost session started on \(output.name)")
            dispatch(.sessionCreated)
        } catch {
            graph.stop()
            if let createdAggregate {
                taps.destroyAggregateDevice(createdAggregate)
            }
            if let createdTap {
                taps.destroyTap(createdTap)
            }
            session = nil
            let boostError = (error as? BoostError) ?? .invariant(error.localizedDescription)
            logger.log(level: .error, "Session creation failed: \(boostError.userMessage)")
            dispatch(.sessionFailed(boostError))
        }
    }

    private func applyConfiguration() {
        graph.apply(configuration.processingChain)
    }

    private func teardownSession() {
        graph.stop()
        if let session {
            taps.destroyAggregateDevice(session.aggregateDeviceID)
            taps.destroyTap(session.tap)
        }
        session = nil
        logger.log(level: .debug, "Session torn down")
        if stateMachine.state == .stopping {
            dispatch(.sessionTornDown)
        }
    }
}
