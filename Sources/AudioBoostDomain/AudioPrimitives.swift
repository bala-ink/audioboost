import Foundation

public struct AudioProcessRef: Equatable, Sendable {
    public let objectID: UInt32

    public init(objectID: UInt32) {
        self.objectID = objectID
    }
}

public struct OutputDevice: Equatable, Sendable {
    public let identifier: UInt32
    public let uid: String
    public let name: String
    public let streamIndex: Int
    public let format: AudioFormatDescriptor

    public init(
        identifier: UInt32,
        uid: String,
        name: String,
        streamIndex: Int = 0,
        format: AudioFormatDescriptor = AudioFormatDescriptor()
    ) {
        self.identifier = identifier
        self.uid = uid
        self.name = name
        self.streamIndex = streamIndex
        self.format = format
    }
}

public struct TapHandle: Equatable, Sendable {
    public let objectID: UInt32
    public let uid: String

    public init(objectID: UInt32, uid: String) {
        self.objectID = objectID
        self.uid = uid
    }
}

public enum TapMuteBehavior: String, Equatable, Sendable, CaseIterable {
    case unmuted
    case muted
    case mutedWhenTapped
}

public struct TapConfiguration: Equatable, Sendable {
    public var name: String
    public var isPrivate: Bool
    public var muteBehavior: TapMuteBehavior
    public var excludedProcessIDs: [UInt32]
    public var deviceUID: String
    public var streamIndex: Int

    public init(
        name: String,
        isPrivate: Bool,
        muteBehavior: TapMuteBehavior,
        excludedProcessIDs: [UInt32],
        deviceUID: String,
        streamIndex: Int
    ) {
        self.name = name
        self.isPrivate = isPrivate
        self.muteBehavior = muteBehavior
        self.excludedProcessIDs = excludedProcessIDs
        self.deviceUID = deviceUID
        self.streamIndex = streamIndex
    }
}

public enum TapConfigurationFactory {
    public static func systemWide(
        excluding process: AudioProcessRef,
        output: OutputDevice,
        name: String = "AudioBoost Tap"
    ) -> TapConfiguration {
        TapConfiguration(
            name: name,
            isPrivate: true,
            muteBehavior: .mutedWhenTapped,
            excludedProcessIDs: [process.objectID],
            deviceUID: output.uid,
            streamIndex: output.streamIndex
        )
    }
}

public struct AggregateDeviceDescriptor: Equatable, Sendable {
    public var name: String
    public var uid: String
    public var isPrivate: Bool
    public var isStacked: Bool
    public var tapUID: String
    public var outputDeviceUID: String
    public var tapAutoStart: Bool
    public var driftCompensation: Bool

    public init(
        name: String,
        uid: String,
        isPrivate: Bool,
        isStacked: Bool,
        tapUID: String,
        outputDeviceUID: String,
        tapAutoStart: Bool,
        driftCompensation: Bool
    ) {
        self.name = name
        self.uid = uid
        self.isPrivate = isPrivate
        self.isStacked = isStacked
        self.tapUID = tapUID
        self.outputDeviceUID = outputDeviceUID
        self.tapAutoStart = tapAutoStart
        self.driftCompensation = driftCompensation
    }
}

public enum AggregateDeviceFactory {
    public static func make(
        tap: TapHandle,
        output: OutputDevice,
        uid: String = UUID().uuidString,
        name: String = "AudioBoost Aggregate"
    ) -> AggregateDeviceDescriptor {
        AggregateDeviceDescriptor(
            name: name,
            uid: uid,
            isPrivate: true,
            isStacked: false,
            tapUID: tap.uid,
            outputDeviceUID: output.uid,
            tapAutoStart: true,
            driftCompensation: true
        )
    }
}

public struct GraphPlan: Equatable, Sendable {
    public let aggregateDeviceID: UInt32
    public let outputDevice: OutputDevice
    public let chain: ProcessingChain

    public init(aggregateDeviceID: UInt32, outputDevice: OutputDevice, chain: ProcessingChain) {
        self.aggregateDeviceID = aggregateDeviceID
        self.outputDevice = outputDevice
        self.chain = chain
    }
}
