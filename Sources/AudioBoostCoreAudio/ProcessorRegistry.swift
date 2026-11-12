import AudioBoostDomain
import AudioToolbox
import Foundation

public struct ProcessorComponent: Equatable, Sendable {
    public let type: OSType
    public let subType: OSType
    public let manufacturer: OSType

    public init(type: OSType, subType: OSType, manufacturer: OSType) {
        self.type = type
        self.subType = subType
        self.manufacturer = manufacturer
    }
}

public enum ProcessorKind: String, CaseIterable, Sendable {
    case dynamicsProcessor
    case peakLimiter
}

/// Maps processing-chain nodes onto Apple Audio Units. Adding a new effect means
/// adding a node case plus a registry entry, without touching the coordinator.
public enum ProcessorRegistry {
    public static func kind(for node: ProcessingNode) -> ProcessorKind? {
        switch node {
        case .gain:
            return nil
        case .compressor:
            return .dynamicsProcessor
        case .limiter:
            return .peakLimiter
        }
    }

    public static func component(for kind: ProcessorKind) -> ProcessorComponent {
        switch kind {
        case .dynamicsProcessor:
            return ProcessorComponent(
                type: kAudioUnitType_Effect,
                subType: kAudioUnitSubType_DynamicsProcessor,
                manufacturer: kAudioUnitManufacturer_Apple
            )
        case .peakLimiter:
            return ProcessorComponent(
                type: kAudioUnitType_Effect,
                subType: kAudioUnitSubType_PeakLimiter,
                manufacturer: kAudioUnitManufacturer_Apple
            )
        }
    }

    public static func audioComponentDescription(for kind: ProcessorKind) -> AudioComponentDescription {
        let component = component(for: kind)
        return AudioComponentDescription(
            componentType: component.type,
            componentSubType: component.subType,
            componentManufacturer: component.manufacturer,
            componentFlags: 0,
            componentFlagsMask: 0
        )
    }
}
