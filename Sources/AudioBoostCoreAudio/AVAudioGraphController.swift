import AVFoundation
import AudioBoostDomain
import AudioToolbox
import CoreAudio
import Foundation

/// Owns the real-time audio graph. All DSP happens inside Apple Audio Units, so no
/// Swift code runs on the render thread.
public final class AVAudioGraphController: AudioGraphProviding {
    private let engine = AVAudioEngine()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 1)
    private let dynamics = AVAudioUnitEffect(
        audioComponentDescription: ProcessorRegistry.audioComponentDescription(for: .dynamicsProcessor)
    )
    private let limiter = AVAudioUnitEffect(
        audioComponentDescription: ProcessorRegistry.audioComponentDescription(for: .peakLimiter)
    )

    private var attached = false

    public init() {}

    public func build(_ plan: GraphPlan) throws {
        stop()
        resetGraph()

        try bind(deviceID: plan.aggregateDeviceID)

        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        let format: AVAudioFormat
        if inputFormat.sampleRate > 0, inputFormat.channelCount > 0 {
            format = inputFormat
        } else if let fallback = AVAudioFormat(
            standardFormatWithSampleRate: plan.outputDevice.format.sampleRate,
            channels: AVAudioChannelCount(plan.outputDevice.format.channelCount)
        ) {
            format = fallback
        } else {
            throw BoostError.graphBuildFailed(reason: "The output device reported an invalid audio format.")
        }

        engine.attach(equalizer)
        engine.attach(dynamics)
        engine.attach(limiter)
        attached = true

        equalizer.bands.first?.bypass = true

        engine.connect(engine.inputNode, to: equalizer, format: format)
        engine.connect(equalizer, to: dynamics, format: format)
        engine.connect(dynamics, to: limiter, format: format)
        engine.connect(limiter, to: engine.mainMixerNode, format: format)

        apply(plan.chain)
    }

    public func start() throws {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            throw BoostError.engineStartFailed(reason: error.localizedDescription)
        }
    }

    public func stop() {
        if engine.isRunning {
            engine.stop()
        }
    }

    public func apply(_ chain: ProcessingChain) {
        for node in chain.nodes {
            switch node {
            case .gain(let gain):
                equalizer.globalGain = gain.decibels

            case .compressor(let configuration):
                dynamics.bypass = !configuration.isEnabled
                let unit = dynamics.audioUnit
                set(unit, kDynamicsProcessorParam_Threshold, configuration.thresholdDB)
                set(unit, kDynamicsProcessorParam_HeadRoom, configuration.headRoomDB)
                set(unit, kDynamicsProcessorParam_AttackTime, configuration.attackSeconds)
                set(unit, kDynamicsProcessorParam_ReleaseTime, configuration.releaseSeconds)
                set(unit, kDynamicsProcessorParam_OverallGain, configuration.makeupGainDB)

            case .limiter(let configuration):
                limiter.bypass = !configuration.isEnabled
                let unit = limiter.audioUnit
                set(unit, kLimiterParam_AttackTime, configuration.attackSeconds)
                set(unit, kLimiterParam_DecayTime, configuration.decaySeconds)
                set(unit, kLimiterParam_PreGain, configuration.preGainDB)
            }
        }
    }

    private func bind(deviceID: AudioObjectID) throws {
        if let inputUnit = engine.inputNode.audioUnit {
            var device = deviceID
            let status = AudioUnitSetProperty(
                inputUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &device,
                UInt32(MemoryLayout<AudioObjectID>.size)
            )
            guard status == noErr else {
                throw BoostError.graphBuildFailed(reason: "Could not bind the input device (error \(status)).")
            }
        }

        if let outputUnit = engine.outputNode.audioUnit {
            var device = deviceID
            let status = AudioUnitSetProperty(
                outputUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &device,
                UInt32(MemoryLayout<AudioObjectID>.size)
            )
            guard status == noErr else {
                throw BoostError.graphBuildFailed(reason: "Could not bind the output device (error \(status)).")
            }
        }
    }

    private func set(_ unit: AudioUnit, _ parameterID: AudioUnitParameterID, _ value: Float) {
        AudioUnitSetParameter(unit, parameterID, kAudioUnitScope_Global, 0, value, 0)
    }

    private func resetGraph() {
        guard attached else { return }
        engine.stop()
        engine.disconnectNodeOutput(engine.inputNode)
        engine.disconnectNodeOutput(equalizer)
        engine.disconnectNodeOutput(dynamics)
        engine.disconnectNodeOutput(limiter)
        engine.detach(equalizer)
        engine.detach(dynamics)
        engine.detach(limiter)
        attached = false
    }
}
