# Security Policy

## Supported versions

AudioBoost is built from source and has no released binary distribution yet.
Security fixes are applied to the `main` branch.

## Reporting a vulnerability

Please do not open a public issue for security problems. Use GitHub's private
vulnerability reporting:

<https://github.com/bala-ink/audioboost/security/advisories/new>

Include a description, reproduction steps, and the macOS version you tested.
You can expect an initial response within a few days.

## Scope

AudioBoost requests the System Audio Recording permission and processes audio in
memory. It does not record, store, or transmit audio. Reports about permission
handling, resource leaks, or unsafe parsing of Core Audio data are especially
welcome.
