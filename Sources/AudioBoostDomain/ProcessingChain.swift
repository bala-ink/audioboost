import Foundation

/// Linear gain expressed in decibels.
public struct GainConfiguration: Equatable, Sendable {
    public static let minimumDecibels: Float = -96
    public static let maximumDecibels: Float = 24

    public var decibels: Float

    public init(decibels: Float) {
        self.decibels = Self.clamped(decibels)
    }

    public static func clamped(_ decibels: Float) -> Float {
        guard decibels.isFinite else { return 0 }
        return min(maximumDecibels, max(minimumDecibels, decibels))
    }

    public var linearGain: Float {
        Float(pow(10.0, Double(decibels) / 20.0))
    }
}

public struct CompressorConfiguration: Equatable, Sendable {
    public var isEnabled: Bool
    public var thresholdDB: Float
    public var headRoomDB: Float
    public var attackSeconds: Float
    public var releaseSeconds: Float
    public var makeupGainDB: Float

    public init(
        isEnabled: Bool = true,
        thresholdDB: Float = -20,
        headRoomDB: Float = 6,
        attackSeconds: Float = 0.005,
        releaseSeconds: Float = 0.15,
        makeupGainDB: Float = 3
    ) {
        self.isEnabled = isEnabled
        self.thresholdDB = thresholdDB
        self.headRoomDB = headRoomDB
        self.attackSeconds = attackSeconds
        self.releaseSeconds = releaseSeconds
        self.makeupGainDB = makeupGainDB
    }
}

public struct LimiterConfiguration: Equatable, Sendable {
    public var isEnabled: Bool
    public var attackSeconds: Float
    public var decaySeconds: Float
    public var preGainDB: Float

    public init(
        isEnabled: Bool = true,
        attackSeconds: Float = 0.001,
        decaySeconds: Float = 0.05,
        preGainDB: Float = 0
    ) {
        self.isEnabled = isEnabled
        self.attackSeconds = attackSeconds
        self.decaySeconds = decaySeconds
        self.preGainDB = preGainDB
    }
}

public enum ProcessingNode: Equatable, Sendable {
    case gain(GainConfiguration)
    case compressor(CompressorConfiguration)
    case limiter(LimiterConfiguration)
}

public struct ProcessingChain: Equatable, Sendable {
    public var nodes: [ProcessingNode]

    public init(nodes: [ProcessingNode]) {
        self.nodes = nodes
    }

    public static func standard(
        gainDecibels: Float,
        compressorEnabled: Bool,
        limiterEnabled: Bool = true
    ) -> ProcessingChain {
        ProcessingChain(nodes: [
            .gain(GainConfiguration(decibels: gainDecibels)),
            .compressor(CompressorConfiguration(isEnabled: compressorEnabled)),
            .limiter(LimiterConfiguration(isEnabled: limiterEnabled)),
        ])
    }
}
