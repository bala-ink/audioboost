import AppKit
import AudioBoostCore
import AudioBoostDomain
import SwiftUI

public struct ContentView: View {
    @ObservedObject private var coordinator: BoostCoordinator

    public init(coordinator: BoostCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            HStack {
                Text("Gain")
                Slider(
                    value: Binding(
                        get: { Double(coordinator.configuration.gainDecibels) },
                        set: { coordinator.setGain(Float($0)) }
                    ),
                    in: Double(GainConfiguration.minimumDecibels)...Double(GainConfiguration.maximumDecibels),
                    step: 1
                )
                Text(BoostFormatting.gainLabel(coordinator.configuration.gainDecibels))
                    .monospacedDigit()
                    .frame(width: 64, alignment: .trailing)
            }

            Toggle(
                "Compressor (lift quiet dialogue)",
                isOn: Binding(
                    get: { coordinator.configuration.compressorEnabled },
                    set: { coordinator.setCompressorEnabled($0) }
                )
            )

            Toggle(
                "Limiter (prevent clipping)",
                isOn: Binding(
                    get: { coordinator.configuration.limiterEnabled },
                    set: { coordinator.setLimiterEnabled($0) }
                )
            )

            if let suggestion = BoostFormatting.recoverySuggestion(for: coordinator.state) {
                Text(suggestion)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Button(coordinator.isRunning ? "Stop" : "Start") {
                    if coordinator.isRunning {
                        coordinator.stop()
                    } else {
                        coordinator.start()
                    }
                }
                .disabled(!coordinator.isRunning && !BoostFormatting.isStartEnabled(for: coordinator.state))

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: coordinator.isRunning ? "waveform" : "speaker.slash")
                .foregroundStyle(coordinator.isRunning ? Color.green : Color.secondary)
            Text("Audio Boost")
                .font(.headline)
            Spacer()
            Text(BoostFormatting.statusLabel(for: coordinator.state))
                .font(.caption)
                .foregroundStyle(coordinator.isRunning ? Color.green : Color.secondary)
                .lineLimit(1)
        }
    }
}
