import Foundation

public struct AudioFormatDescriptor: Equatable, Sendable {
    public var sampleRate: Double
    public var channelCount: Int

    public init(sampleRate: Double = 48_000, channelCount: Int = 2) {
        self.sampleRate = sampleRate > 0 ? sampleRate : 48_000
        self.channelCount = max(1, channelCount)
    }
}
