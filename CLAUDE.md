# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

macOS 14+ menu bar app (SwiftUI `MenuBarExtra`, `LSUIElement`) plus a medium WidgetKit widget, counting down to the user's layoff moment. It's a dark joke shared with a local team and passed around as an unsigned DMG. Spec: `docs/superpowers/specs/2026-10-22-layoff-countdown-design.md`. The plan in `docs/superpowers/plans/` holds the decisions made so far and the exact UI strings.

## Commands

```sh
swift test --package-path Packages/LayoffCore                                  # all logic tests
swift test --package-path Packages/LayoffCore --filter CountdownTests/testShort # one test
xcodebuild -project LayoffCountdown.xcodeproj -scheme LayoffCountdown -configuration Debug -derivedDataPath build build
xcodegen generate             # after any change to project.yml
bash scripts/make-dmg.sh      # Release build -> dist/LayoffCountdown.dmg
bash scripts/make-icon.sh     # redraw App/Assets.xcassets/AppIcon.appiconset from scripts/make-icon.swift
```

All tests live in the `LayoffCore` package; the Xcode targets have none. There is no linter.

## Hard rules

- **No network access at all.** Don't use `URLSession` or add analytics, crash reporters, third-party runtime dependencies or a network entitlement. `make-dmg.sh` fails if a network entitlement shows up.
- **The shared DMG must not identify the builder.** `make-dmg.sh` always builds ad-hoc with `DEVELOPMENT_TEAM=`, `APP_GROUP_ID=` and `Config/AdHoc.entitlements`. A `codesign` check then fails the script if a team ID or the `application-groups` entitlement is present. Keep those overrides and that check.
- **Jokes** (`Jokes.swift`) stay about the situation. Never name a person or a company.
- **`project.yml` is the source of truth.** Don't hand-edit `LayoffCountdown.xcodeproj`, the `Info.plist` files or the `.entitlements` files in `App/` and `Widget/`. Change `project.yml`, run `xcodegen generate`, and commit the regenerated `.xcodeproj`. On a `project.pbxproj` merge conflict, regenerate instead of merging by hand.
- **Exact strings and formats** are fixed by the spec and plan. Menu bar: `💀 23d 4h`, full style `💀 23d 4:17:52` (hours unpadded; `M:SS` when the day's hours are 0), `💀 Set date`, `💀 Goodbye`. Never show negative values or overtime.

## Architecture

Three parts: `App/` (menu bar app and settings window), `Widget/` (widget extension), and `Packages/LayoffCore` (all logic, no UI, unit-tested). Both targets depend on `LayoffCore`. Put new logic there, with tests.

- **Time model.** A "day" is exactly 86,400 s counted back from the deadline, not a calendar day. The menu bar and the widget agree only because both use this rule (`Countdown.swift`, `WidgetSchedule.swift`). `CountdownState` is `notSet`, `counting` or `done`.
- **Menu bar.** `Ticker` publishes once a second, aligned to whole seconds, in `.common` run-loop mode. Only the label, the dropdown and the settings preview observe it, so the settings form doesn't redraw while you type. `AppModel` is `@MainActor`, and its `settings` are `private(set)`. Change them only through `update(_:)`, which saves and calls `WidgetCenter.reloadAllTimelines()`.
- **Widget clock.** Widgets can't redraw every second. The clock is `Text(verbatim: "\(days)d ")` followed by `Text(timerInterval:)` running to the next day boundary. `WidgetSchedule` adds an entry 1 s *after* each day boundary, so a zero-length timer never freezes. It also adds entries at the deadline and at local midnight for the daily joke. The progress bar is `ProgressView(timerInterval:)`.
- **Widget dates.** `LayoffWidgetIntent` (Edit Widget) has its own **Layoff date**, **Layoff time** and **Notice started**. Edit Widget on macOS shows dates without a time, so the dates are days only and the time is an hour picker (`LayoffHour`). `LayoffSettings.widget(layoffDay:hour:startDay:shared:calendar:)` merges them: a widget date wins, otherwise the App Group settings, otherwise not set.
- **Settings storage.** `SettingsStore` keeps `LayoffSettings` as JSON under the key `layoffSettings.v1`, with lenient decoding (a bad emoji or style falls back to the default). It uses the App Group when `AppGroup.current` is non-nil, and otherwise the app's own defaults. It also copies existing settings into the App Group once, the first time one is available.
  - On macOS, `containerURL(forSecurityApplicationGroupIdentifier:)` returns non-nil for *any* ID. Don't use it as a check.
  - The real check is `AppGroup.current`, which reads `LCAppGroupID` from Info.plist. It passes the value through `AppGroup.identifier(from:)`, which rejects an empty value, a leading `.` and an unexpanded `$(`.
- **Signing.** `Config/Signing.xcconfig` (committed, team empty) includes the gitignored `Signing.local.xcconfig`. `APP_GROUP_ID` is derived from `DEVELOPMENT_TEAM`.
  - Without a team, the build is ad-hoc. The menu bar works, but the widget can't read its settings. It shows `Right-click › Edit Widget to set your date` until its own dates are set.
  - With Personal Team signing, the widget can read the settings. Never ship such a build.

## Working on the running app

- The app is sandboxed. Its preferences live at `~/Library/Containers/com.layoffcountdown.app/Data/Library/Preferences/com.layoffcountdown.app`. Plain `defaults delete com.layoffcountdown.app` doesn't reach them. Use the full path form shown in README.md › Reset.
- Checks an agent can run: `pgrep -x LayoffCountdown`, `lsappinfo`, `codesign -d --entitlements - <bundle>`, `pluginkit -mAvvv -i com.layoffcountdown.app.widget`. Anything visual needs a human to look.
- Toolchain: Xcode 16+, `SWIFT_VERSION` 5.0. XcodeGen comes from `brew install xcodegen`, and you need it only after changing `project.yml`.
