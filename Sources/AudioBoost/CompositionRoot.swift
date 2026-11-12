import AudioBoostCore
import AudioBoostCoreAudio

enum CompositionRoot {
    @MainActor
    static func makeCoordinator() -> BoostCoordinator {
        BoostCoordinator(
            capabilities: SystemCapabilityProbe(),
            processes: SystemProcessLocator(),
            taps: CoreAudioTapController(),
            outputs: SystemOutputDeviceProvider(),
            graph: AVAudioGraphController(),
            logger: ConsoleBoostLogger()
        )
    }
}
