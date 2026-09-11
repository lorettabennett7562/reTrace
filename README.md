# ReTrace

Offline-first iOS utility that helps you disassemble, disconnect, move, repair, pack, or temporarily remove
physical items — then restore them later in the correct reverse order. See `ReTrace_iOS_Development_Spec.md`
(provided separately) for the full product specification.

> Capture how it comes apart now, so you can put it back correctly later.

## Requirements

- Xcode 26 (or newer), iOS 26 SDK, deployment target iOS 17.0
- No third-party dependencies — the project has zero Swift Package Manager packages

## Project layout

```
ReTrace/              App target (SwiftUI + SwiftData)
  App/                 Entry point, DI container, router, root/tab views
  Core/                Design system, persistence, media, notifications, export, utilities
  Features/            One folder per feature (Projects, Capture, Parts, Restore, Settings, ...)
  Models/              RTProject, RTStep, RTPart, RTConnection SwiftData models
  Assets.xcassets/     Gray-mix color tokens, app icon
ReTraceTests/          XCTest unit tests for the business-logic engines
ReTraceUITests/        XCUITest end-to-end tests for critical user flows
codemagic.yaml         Codemagic CI configuration (tests + App Store build)
```

## Core product loop

```
Create Project → Capture Original State → Record Disassembly Steps → Store Parts / Connections
→ Finish Disassembly → (later) Restore Mode → Follow steps in reverse → Confirm each step → Complete Project
```

A step can be recorded with a photo, with just a type + note, or both — a picture is never required to
document what happened. The Project Detail screen can show the sequence either as a photo timeline or as a
flow diagram (icons + notes only), so the whole app works whether or not you take pictures.

## Building locally

```bash
xcodebuild -project ReTrace.xcodeproj -scheme ReTrace \
  -destination 'generic/platform=iOS Simulator' build
```

## Running tests

```bash
# Unit tests
xcodebuild -project ReTrace.xcodeproj -scheme ReTrace \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ReTraceTests test

# UI tests
xcodebuild -project ReTrace.xcodeproj -scheme ReTrace \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ReTraceUITests test

# iPad layout tests
xcodebuild -project ReTrace.xcodeproj -scheme ReTrace \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:ReTraceUITests/iPadLayoutUITests test
```

## Codemagic

`codemagic.yaml` defines three workflows:

- `retrace-tests` — unit + UI tests on an iPhone simulator (runs on every push).
- `retrace-ipad-tests` — the iPad-specific layout UI tests.
- `retrace-release` — signs and archives a build for TestFlight. Requires an `app_store_connect`
  integration named `retraceApi` to be configured in the Codemagic team settings (API key + issuer ID),
  plus automatic code signing certificates/profiles managed by Codemagic.

## Product safety

ReTrace stores the user's own recorded steps and photos. It never invents disassembly/repair instructions
and never claims a connection or step is "correct" or "safe" — only that it matches what the user recorded.

## Privacy

Everything is stored locally in the app's own container. There is no backend, account, login, or analytics
connection — the app works fully offline.
