import AudioBoostDomain
import Testing

@testable import AudioBoostUI

@Suite("Boost formatting")
struct BoostFormattingTests {
    private let unsupported = CapabilityReport(
        supportsProcessTap: false,
        hasOutputDevice: false,
        operatingSystemDescription: "test"
    )

    @Test("Gain labels include the sign")
    func gainLabels() {
        #expect(BoostFormatting.gainLabel(12) == "+12 dB")
        #expect(BoostFormatting.gainLabel(0) == "+0 dB")
        #expect(BoostFormatting.gainLabel(-6) == "-6 dB")
        #expect(BoostFormatting.gainLabel(6.6) == "+7 dB")
    }

    @Test("Status labels describe each state")
    func statusLabels() {
        #expect(BoostFormatting.statusLabel(for: .idle) == "Idle")
        #expect(BoostFormatting.statusLabel(for: .running) == "Running")
        #expect(BoostFormatting.statusLabel(for: .preparing) == "Starting…")
        #expect(BoostFormatting.statusLabel(for: .failed(.noOutputDevice)) == BoostError.noOutputDevice.userMessage)
        #expect(
            BoostFormatting.statusLabel(for: .unsupported(unsupported))
                == BoostError.unsupportedOperatingSystem(required: "macOS 14.2 or later").userMessage
        )
    }

    @Test("Recovery suggestions only appear for actionable states")
    func recoverySuggestions() {
        #expect(BoostFormatting.recoverySuggestion(for: .idle) == nil)
        #expect(BoostFormatting.recoverySuggestion(for: .running) == nil)
        #expect(BoostFormatting.recoverySuggestion(for: .failed(.noOutputDevice)) != nil)
        #expect(BoostFormatting.recoverySuggestion(for: .unsupported(unsupported)) != nil)
    }

    @Test("Start is only enabled from restartable states")
    func startEnabled() {
        #expect(BoostFormatting.isStartEnabled(for: .idle))
        #expect(BoostFormatting.isStartEnabled(for: .suspended))
        #expect(BoostFormatting.isStartEnabled(for: .failed(.noOutputDevice)))
        #expect(!BoostFormatting.isStartEnabled(for: .preparing))
        #expect(!BoostFormatting.isStartEnabled(for: .running))
        #expect(!BoostFormatting.isStartEnabled(for: .stopping))
        #expect(!BoostFormatting.isStartEnabled(for: .unsupported(unsupported)))
    }
}
