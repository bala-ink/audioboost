import AudioBoostCore
import AudioBoostUI
import SwiftUI

@main
struct AudioBoostApp: App {
    @StateObject private var coordinator: BoostCoordinator

    init() {
        _coordinator = StateObject(wrappedValue: CompositionRoot.makeCoordinator())
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(coordinator: coordinator)
        } label: {
            Image(systemName: coordinator.isRunning ? "waveform" : "speaker.slash")
        }
        .menuBarExtraStyle(.window)
    }
}
