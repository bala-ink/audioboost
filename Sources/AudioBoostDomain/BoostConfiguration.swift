import Foundation

public struct BoostConfiguration: Equatable, Sendable {
    public var gainDecibels: Float
    public var compressorEnabled: Bool
    public var limiterEnabled: Bool

    public init(gainDecibels: Float = 12, compressorEnabled: Bool = true, limiterEnabled: Bool = true) {
        self.gainDecibels = GainConfiguration.clamped(gainDecibels)
        self.compressorEnabled = compressorEnabled
        self.limiterEnabled = limiterEnabled
    }

    public var processingChain: ProcessingChain {
        .standard(
            gainDecibels: gainDecibels,
            compressorEnabled: compressorEnabled,
            limiterEnabled: limiterEnabled
        )
    }

    public mutating func setGain(_ decibels: Float) {
        gainDecibels = GainConfiguration.clamped(decibels)
    }
}
