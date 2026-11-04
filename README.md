# ReTrace

Offline-first iOS utility that helps you disassemble, disconnect, move, repair, pack, or temporarily remove
physical items — then restore them later in the correct reverse order. See `ReTrace_iOS_Development_Spec.md`
(provided separately) for the full product specification.

> Capture how it comes apart now, so you can put it back correctly later.

## Requirements

- Xcode 26 (or newer), iOS 26 SDK, deployment target iOS 17.0
- Adjust iOS SDK 5.8.1 via Swift Package Manager (including its signature dependency)

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

Projects, steps, parts, connections and photos remain local. On the first uncached launch,
the app POSTs device and campaign attribution metadata to `https://rtrace.xyz/retraceuser`.
Adjust measures installation attribution when its app token is configured. The native utility
continues to work offline; remote web content needs a connection.

## Remote launch and Adjust

The ReTrace Adjust app token is configured in the Xcode build setting
`ADJUST_APP_TOKEN` for Debug and Release (override with `ADJUST_APP_TOKEN=...`
when invoking xcodebuild). With no token the SDK stays disabled;
the launch API still runs with empty attribution. SDK installation follows the
[official Adjust integration guide](https://dev.adjust.com/en/sdk/ios/).

The POST JSON contains `appid`, `idfv`, `pushToken`, `userAgent`, `oneLink`,
`appsAttr` (a JSON string) and `adjustAdid`. Naming includes tracker token/name,
network, campaign, adgroup, creative, click label and available cost fields.
IDFA collection is disabled: no app IDFA reads, no IDFA request field, and
`disableIdfaReading()` is applied before Adjust initialization. There is no ATT prompt. Attribution is best effort, with a maximum 30-second wait;
the SDK cannot guarantee campaign fields that the ad network does not supply.
`pushToken` is always a string; it is `""` when unavailable. ReTrace currently uses
local reminders and has no Firebase setup. `deviceName` is not collected or sent.

The ReTrace launch response uses this contract:

```json
{"retraceFlow":"retraceHub","url":"https://example.com/start"}
```

`retraceHub` opens the returned HTTPS URL in a persistent WKWebView; `questLog` opens
the native app (`{"retraceFlow":"questLog"}`). Both valid decisions persist across launches. Invalid URLs, unknown
flows, HTTP errors or network failures fall back to native UI for that run and
retry next launch. No API response is fabricated or cached on failure.
UI tests bypass the SDK and launch API. `retrace://` links are registered;
universal links require Associated Domains and the domain's AASA configuration.

The marketing Worker handles `POST /retraceuser` for `com.retrace.lorettapp`.
It validates JSON launch metadata (32 KiB maximum) and returns `questLog` with
English project templates by default. Validated launch fields are stored in the private `RETRACE_LAUNCH_LOGS`
Cloudflare KV binding with a 24-hour TTL. Unknown fields are not stored; there is
no public log-reading endpoint. Requests containing a top-level `idfa` field are rejected.
Set the Worker variable `RETRACE_WEB_URL` to an HTTPS destination to return
`retraceHub` instead; without that variable the native response is used.
Responses have `Cache-Control: no-store`. Other methods return 405.


Native launch responses can supply useful project templates (no `url` field):

```json
{
  "retraceFlow": "questLog",
  "projectTemplates": [
    {"title": "PC Upgrade", "category": "computer"},
    {"title": "Desk Disassembly", "category": "furniture"},
    {"title": "Pack Console", "category": "packing"}
  ]
}
```

The New Project chips use these templates; tapping one fills its title and category.
Templates are optional: without them, the built-in examples remain available. A supplied
list must contain 1–8 entries with unique titles (1–80 characters, not whitespace only).
Categories: `electronics`, `computer`, `furniture`, `vehicle`, `bicycle`, `appliance`,
`packing`, `home`, `other`. Templates persist with the launch decision and work offline.
They are project labels, not generated repair instructions. UI tests use built-in examples.


## WebView links and payments

HTTP/HTTPS, about, blob and data navigation stay in WebKit. External schemes such
as `mailto:`, `tg:`, `tel:` and `sms:` are passed to iOS from both ordinary links
and new-window requests. If iOS cannot open one, an English error is displayed
instead of silently ignoring the link. A matching app must be installed/configured;
Mail and Telegram are not installed in the current iPhone simulator.
HTTP content is permitted only in WebView using `NSAllowsArbitraryLoadsInWebContent`;
the native launch API still uses HTTPS with normal URLSession ATS protections.
No user scripts are injected into the browsing WebView, preserving WebKit's
Apple Pay compatibility. Apple Pay merchant validation and device/Wallet readiness
are controlled by the website and Apple, not simulated by the app. Use Apple's
[web demo](https://applepaydemo.apple.com/) and
[sandbox testing guide](https://developer.apple.com/apple-pay/sandbox-testing/).
