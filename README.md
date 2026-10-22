# Layoff Countdown

A macOS menu bar app that counts down to your layoff. You enter the moment you're out, and the menu bar shows how much of your career here is left (`💀 23d 4h`). There's also a desktop widget with a ticking clock, a red progress bar for the notice period and a new dark one-liner each day. It's a joke for the team, so treat it like one.

The app has no network access. Your date stays on your Mac and nothing is sent anywhere.

Requires macOS 14 (Sonoma) or later.

## Install

1. Open `LayoffCountdown.dmg` and drag `LayoffCountdown.app` to `Applications`.
2. Open the app. macOS blocks it the first time, because the app isn't signed by a registered developer.
3. Go to System Settings › Privacy & Security, scroll down and click **Open Anyway** next to the message about LayoffCountdown. Then open the app again.

You can also clear the quarantine flag in Terminal instead of step 3:

```sh
xattr -dr com.apple.quarantine /Applications/LayoffCountdown.app
```

Right-click › Open no longer gets past Gatekeeper on macOS 15 and later.

The app lives in the menu bar only. It has no Dock icon. To quit it, click the menu bar item and choose **Quit Layoff Countdown**.

## Set your date

On first launch the settings window opens by itself. Later you can open it from the menu bar item › **Settings…**.

- **Layoff moment**: the date and time you're out (defaults to 17:00, in this Mac's time zone)
- **Announced on**: the day you got the news, which the widget uses for its progress bar
- **Menu bar**: pick an emoji and a style, either short (`💀 23d 4h`) or full (`💀 23d 4:17:52`)
- **Open at login**: start the app when you log in

Click **Save**. When the moment passes, the menu bar says `💀 Goodbye`.

The full style shows hours without padding and drops to `M:SS` in the last hour of a day (`💀 0d 17:52`), the same way the widget does.

A "day" is exactly 24 hours counted back from the layoff moment, not a calendar day. Across a daylight saving change the day number ticks over one hour off from the wall clock. That's expected.

If **Open at login** needs your approval, the settings window shows an **Open System Settings** button that takes you to System Settings › General › Login Items.

### Reset

The app is sandboxed. In a DMG or other ad-hoc build, its settings live in `~/Library/Containers/com.layoffcountdown.app/Data/Library/Preferences/com.layoffcountdown.app.plist`. To start over, quit the app, then run:

```sh
defaults delete ~/Library/Containers/com.layoffcountdown.app/Data/Library/Preferences/com.layoffcountdown.app layoffSettings.v1
```

In a build signed with your Personal Team, the settings also live in the shared App Group. Delete that copy too, with your team ID in place of `<TEAM>`:

```sh
defaults delete ~/Library/Group\ Containers/<TEAM>.com.layoffcountdown.shared/Library/Preferences/<TEAM>.com.layoffcountdown.shared layoffSettings.v1
```

## Widget

The widget is a bonus. From the shared DMG, it may be listed in the widget gallery, but it will show `Set your date in the app`. The widget can only read the app's settings when both are signed with a real team and share an App Group, and the DMG is not signed that way on purpose (see below). Teammates get the menu bar only. The [second-Mac widget test](#second-mac-widget-test) checks what a teammate's Mac actually does.

The widget works on your own Mac when you build from source with your own Personal Team.

## Updating

Install a new DMG the same way as the first one. Each DMG build looks like a different app to macOS, so you may need to enter your date again and turn **Open at login** off and on again.

## Build from source

You need Xcode 16 or later. The generated `LayoffCountdown.xcodeproj` is committed, so open it and run the `LayoffCountdown` scheme.

XcodeGen is needed only if you change `project.yml`:

```sh
brew install xcodegen
xcodegen generate
```

Shared logic lives in `Packages/LayoffCore` and has its own tests:

```sh
swift test --package-path Packages/LayoffCore
```

### Project layout

```
App/                      menu bar app (SwiftUI MenuBarExtra + settings Window)
Widget/                   WidgetKit extension, medium size only
Packages/LayoffCore/      shared logic, no UI: countdown maths, formatting,
                          settings storage, jokes, widget schedule
Config/Signing.xcconfig   signing settings; overrides go in Signing.local.xcconfig
Config/AdHoc.entitlements sandbox-only entitlements used by the DMG script
project.yml               XcodeGen source for LayoffCountdown.xcodeproj
scripts/make-dmg.sh       Release build + DMG
docs/superpowers/         design spec and implementation plan
```

`project.yml` is the source of truth. Don't hand-edit the `.xcodeproj`, the `Info.plist` files or the `.entitlements` in `App/` and `Widget/`; change `project.yml` and run `xcodegen generate`.

### How it works

- **Countdown.** `CountdownState` is `notSet`, `counting` or `done`. `CountdownFormatter` turns the remaining seconds into `23d 4h` or `23d 4:17:52`. One day is 86,400 seconds counted back from the layoff moment, so the menu bar and the widget always agree.
- **Menu bar.** `Ticker` publishes the time once a second, aligned to whole seconds. Only the menu bar label, the dropdown and the settings preview observe it, so the settings form doesn't redraw while you type. `AppModel` holds the settings and saves them.
- **Settings storage.** `SettingsStore` keeps `LayoffSettings` as JSON under the `layoffSettings.v1` key. It uses the App Group when the build has a team (`AppGroup.current`), and the app's own defaults otherwise. When a team is added later, it copies the existing settings into the App Group once.
- **Widget.** Widgets can't redraw every second, so the clock is `Nd ` plus a system timer (`Text(timerInterval:)`) counting down to the next day boundary. `WidgetSchedule` adds a timeline entry one second after each day boundary, at the deadline, and at local midnight for the daily joke. The progress bar is a self-updating `ProgressView(timerInterval:)` from **Announced on** to the layoff moment.
- **Jokes.** 30 one-liners in `Jokes.swift`, one per day, picked by days since 2026-01-01. Keep them about the situation; never name a person or a company.

### Signing for your own Mac

Without a team the app builds ad-hoc ("Sign to Run Locally") and the menu bar works fully. To get the widget reading your settings, sign with your free Apple ID Personal Team:

1. Create `Config/Signing.local.xcconfig` (gitignored) with both lines:

   ```
   DEVELOPMENT_TEAM = XXXXXXXXXX
   CODE_SIGN_IDENTITY = Apple Development
   ```

   Setting only the team leaves the build ad-hoc signed, and the widget won't see your settings.
2. Build and run from Xcode.

Use this for your own Mac only. Personal Team signing puts your Apple ID name and team ID into the app's signature, so never share a build signed this way.

### Make the DMG

```sh
bash scripts/make-dmg.sh
```

This writes `dist/LayoffCountdown.dmg`. The script always builds ad-hoc without the App Group, even when `Signing.local.xcconfig` sets a team, so no name or team ID ends up in teammates' copies. It stops with an error if a team ID, network entitlement or App Group slips into the build.

## Second-Mac widget test

Run this once on a Mac that didn't build the app, to tell the team what to expect from the DMG:

1. Install the DMG on the second Mac as described in [Install](#install)
2. Set a layoff moment a few days out and click **Save**
3. Check the menu bar shows the countdown
4. Right-click the desktop › Edit Widgets, search for "Layoff Countdown"
5. Note whether the widget appears in the gallery
6. Add the medium widget and note whether it shows your date counting down or `Set your date in the app`

Expected result from the DMG: the widget may or may not be listed, and if it is, it shows `Set your date in the app`.
