import AudioBoostDomain
import AudioToolbox
import Testing

@testable import AudioBoostCoreAudio

@Suite("Processor registry")
struct ProcessorRegistryTests {
    @Test("Maps nodes to processor kinds")
    func kinds() {
        #expect(ProcessorRegistry.kind(for: .gain(GainConfiguration(decibels: 0))) == nil)
        #expect(ProcessorRegistry.kind(for: .compressor(CompressorConfiguration())) == .dynamicsProcessor)
        #expect(ProcessorRegistry.kind(for: .limiter(LimiterConfiguration())) == .peakLimiter)
    }

    @Test("Uses Apple effect Audio Units")
    func components() {
        let dynamics = ProcessorRegistry.component(for: .dynamicsProcessor)
        #expect(dynamics.type == kAudioUnitType_Effect)
        #expect(dynamics.subType == kAudioUnitSubType_DynamicsProcessor)
        #expect(dynamics.manufacturer == kAudioUnitManufacturer_Apple)

        let limiter = ProcessorRegistry.component(for: .peakLimiter)
        #expect(limiter.type == kAudioUnitType_Effect)
        #expect(limiter.subType == kAudioUnitSubType_PeakLimiter)
        #expect(limiter.manufacturer == kAudioUnitManufacturer_Apple)
    }

    @Test("Builds AudioComponent descriptions")
    func descriptions() {
        let description = ProcessorRegistry.audioComponentDescription(for: .peakLimiter)
        #expect(description.componentType == kAudioUnitType_Effect)
        #expect(description.componentSubType == kAudioUnitSubType_PeakLimiter)
        #expect(description.componentManufacturer == kAudioUnitManufacturer_Apple)
    }
}
