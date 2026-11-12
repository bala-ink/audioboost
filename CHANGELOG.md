# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-12

### Added

- Menu-bar app that boosts all system audio using Core Audio process taps.
- Gain control from 0 to +24 dB with a default of +12 dB.
- Optional dynamics compressor and peak limiter.
- Automatic suspension when the default output device changes.
- Clean teardown of taps, aggregate devices, and the audio graph on stop or failure.
- State-machine-driven coordinator with unit tests and fake system adapters.
- Release build script that assembles and ad-hoc signs `AudioBoost.app`.
