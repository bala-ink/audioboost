import Testing

@testable import AudioBoostDomain

@Suite("Gain configuration")
struct GainConfigurationTests {
    @Test("Clamps to the supported decibel range")
    func clampsRange() {
        #expect(GainConfiguration(decibels: 100).decibels == GainConfiguration.maximumDecibels)
        #expect(GainConfiguration(decibels: -500).decibels == GainConfiguration.minimumDecibels)
        #expect(GainConfiguration(decibels: 6).decibels == 6)
    }

    @Test("Non-finite input becomes 0 dB")
    func nonFinite() {
        #expect(GainConfiguration(decibels: .nan).decibels == 0)
        #expect(GainConfiguration(decibels: .infinity).decibels == 0)
    }

    @Test("Converts decibels to linear gain")
    func linearGain() {
        #expect(abs(GainConfiguration(decibels: 0).linearGain - 1.0) < 0.0001)
        #expect(abs(GainConfiguration(decibels: 20).linearGain - 10.0) < 0.0001)
        #expect(abs(GainConfiguration(decibels: -20).linearGain - 0.1) < 0.0001)
    }
}

@Suite("Boost configuration")
struct BoostConfigurationTests {
    @Test("Default configuration")
    func defaults() {
        let configuration = BoostConfiguration()
        #expect(configuration.gainDecibels == 12)
        #expect(configuration.compressorEnabled)
        #expect(configuration.limiterEnabled)
    }

    @Test("setGain clamps")
    func setGainClamps() {
        var configuration = BoostConfiguration()
        configuration.setGain(100)
        #expect(configuration.gainDecibels == GainConfiguration.maximumDecibels)
    }

    @Test("Processing chain reflects configuration")
    func processingChain() {
        let configuration = BoostConfiguration(gainDecibels: 6, compressorEnabled: false, limiterEnabled: false)
        let chain = configuration.processingChain
        #expect(chain.nodes.count == 3)

        guard case .gain(let gain) = chain.nodes[0] else {
            Issue.record("Expected gain node first")
            return
        }
        #expect(gain.decibels == 6)

        guard case .compressor(let compressor) = chain.nodes[1] else {
            Issue.record("Expected compressor node second")
            return
        }
        #expect(compressor.isEnabled == false)

        guard case .limiter(let limiter) = chain.nodes[2] else {
            Issue.record("Expected limiter node third")
            return
        }
        #expect(limiter.isEnabled == false)
    }
}
