# Contributing to AudioBoost

Thanks for helping make quiet dialogue easier to hear.

## Getting started

1. Fork the repository and clone your fork.
2. Build with `swift build`.
3. Run the tests with `./scripts/run-tests.sh`.
4. Lint with `xcrun swift-format lint --recursive Sources Tests Package.swift`.

If you use a full Xcode toolchain, `swift test` works directly. With Command Line
Tools only, use the wrapper script (see the README for details).

## Ground rules

- Keep `AudioBoostDomain` free of Core Audio, AVFoundation, SwiftUI, and other
  system frameworks. New system capabilities belong behind a port in the domain
  and an adapter in `AudioBoostCoreAudio`.
- Add or update tests for behavior changes. The coordinator and state machine
  should stay fully covered by fakes.
- Match the existing style: 4-space indentation, Swift 5 language mode, small
  focused types, no force unwraps.
- Avoid new dependencies unless they are clearly justified in the pull request.
- Do not commit generated artifacts (`.build`, `dist`) or secrets.

## Formatting

The repository ships a `.swift-format` configuration:

```sh
xcrun swift-format format --in-place --recursive Sources Tests scripts/TestLoader.swift Package.swift
xcrun swift-format lint --recursive Sources Tests Package.swift
```

CI runs the lint step, so please run it before opening a pull request.

## Tests

- Unit tests use [Swift Testing](https://github.com/swiftlang/swift-testing).
- Tests that touch real audio hardware are opt-in via
  `AUDIOBOOST_RUN_CORE_AUDIO_TESTS=1`.
- Run a subset with `./scripts/run-tests.sh --filter "Boost coordinator"`.

## Pull requests

- Describe the user-visible change and how you verified it.
- Keep changes focused; split unrelated refactors into separate pull requests.
- Note any macOS version requirements or permission changes.
- If you change audio behavior, include a short manual test plan (apps tested,
  output devices, sample rates).

## Reporting bugs

Please include:

- macOS version and Mac model
- Whether you built from source and which toolchain you used
- The output device and whether the app had System Audio Recording permission
- Steps to reproduce and any console output
