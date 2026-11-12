# AudioBoost

A tiny macOS menu-bar app that makes quiet system audio louder — built for hearing dialogue in streaming apps like Prime Video without turning the whole mix into a shout.

AudioBoost captures system audio with Core Audio process taps (macOS 14.2+), routes it through a gain stage plus a compressor and limiter, and plays it back to your current output device in real time.

> AudioBoost is not affiliated with Amazon, Prime Video, or any streaming service.

## Features

- **+0 to +24 dB boost** with a slider in the main window or menu bar (defaults to +12 dB)
- **Compressor** to lift quiet dialogue and a **limiter** to keep peaks from clipping
- **Works with any app**, because it taps the system audio output rather than a single player
- **Menu-bar control plus a main window** — keeps working when the window is closed
- **Survives output-device changes** by suspending the session safely instead of leaking audio resources
- Pure SwiftUI + Core Audio, no private APIs, no third-party dependencies

## Requirements

- macOS 14.2 or later (Core Audio process taps were introduced in 14.2)
- A Swift 6 toolchain — Command Line Tools or Xcode
- Apple silicon or Intel Mac

## Build and run from source

```sh
git clone https://github.com/bala-ink/audioboost.git
cd audioboost
./scripts/build-app.sh
open dist/AudioBoost.app
```

`scripts/build-app.sh` performs a release build, assembles `dist/AudioBoost.app`, and ad-hoc signs it.

### First launch

1. Open AudioBoost. The main window appears, and a speaker icon is also added to the menu bar.
2. Press **Start**. macOS prompts for **System Audio Recording** permission.
3. Allow AudioBoost in **System Settings → Privacy & Security → Screen & System Audio Recording**.
4. Quit and reopen AudioBoost, then press **Start** again. macOS often requires a relaunch after granting this permission.

Because the app is ad-hoc signed, Gatekeeper may ask you to right-click the app and choose **Open** the first time.

## Usage

- Drag the **Boost** slider to choose the gain.
- Toggle **Compressor** to even out dialogue.
- Toggle **Limiter** to prevent clipping at high gain.
- **Stop** tears the tap and aggregate device down immediately.

AudioBoost captures *all* system audio while running, so music, notifications, and calls are boosted too. Per-app selection is on the roadmap.

## How it works

```
system audio ──► Core Audio process tap ──► aggregate device ──► AVAudioEngine
                                                                     │
                                                     gain ──► compressor ──► limiter
                                                                     │
                                                              output device
```

The codebase is split into small layers:

- `AudioBoostDomain` — pure Swift models, ports, and the `BoostStateMachine` reducer. No system frameworks.
- `AudioBoostCore` — `BoostCoordinator` and `BoostSession`; orchestrates lifecycle through the domain ports.
- `AudioBoostCoreAudio` — real adapters for process taps, aggregate devices, AVAudioEngine, device discovery, and logging.
- `AudioBoostUI` — SwiftUI views and formatting.
- `AudioBoost` — the `@main` menu-bar app and composition root.

Every system dependency sits behind a protocol, so the coordinator is tested with fakes and the Core Audio pieces are tested at the value/description level.

## Development

```sh
swift build
./scripts/run-tests.sh
xcrun swift-format lint --recursive Sources Tests Package.swift
```

`./scripts/run-tests.sh` simply runs `swift test` when a full Xcode toolchain is active. With Command Line Tools only, the bundled `swiftpm-testing-helper` fails to execute Swift Testing bundles on some macOS versions, so the script builds the tests and runs them through a small loader instead.

To run the opt-in integration test that creates a real tap and aggregate device:

```sh
AUDIOBOOST_RUN_CORE_AUDIO_TESTS=1 ./scripts/run-tests.sh
```

### Project layout

```
Sources/AudioBoostDomain/     state, config, ports, errors, reducer
Sources/AudioBoostCore/       coordinator and session lifecycle
Sources/AudioBoostCoreAudio/  Core Audio + AVFoundation adapters
Sources/AudioBoostUI/         SwiftUI menu-bar interface
Sources/AudioBoost/           app entry point and composition root
Tests/                        Swift Testing suites per module
Resources/Info.plist          app bundle metadata
scripts/                      build and test helpers
```

## Limitations and roadmap

- Captures all system audio; choosing individual apps is future work.
- Settings are currently in memory and reset when the app quits.
- Device changes suspend the session; press **Start** to resume.
- No signed or notarized binary releases — build from source.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE)
