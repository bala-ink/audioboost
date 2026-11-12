import AppKit
import AudioBoostCore
import AudioBoostUI
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct AudioBoostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var coordinator: BoostCoordinator

    init() {
        _coordinator = StateObject(wrappedValue: CompositionRoot.makeCoordinator())
    }

    var body: some Scene {
        WindowGroup("AudioBoost") {
            ContentView(coordinator: coordinator)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            ContentView(coordinator: coordinator)
        } label: {
            Image(systemName: coordinator.isRunning ? "waveform" : "speaker.slash")
        }
        .menuBarExtraStyle(.window)
    }
}
