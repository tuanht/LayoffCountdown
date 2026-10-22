# Layoff Countdown — Design

Date: 2026-10-22

## Intent

A native macOS app that counts down to a developer's layoff date. It is a dark joke shared within a local team: everyone runs it, everyone sees their own clock running out. The tone is gallows humor, not a serious planning tool.

## Goals

- Show time remaining to the user's layoff date in the **menu bar** and in a **desktop widget**.
- Provide a **settings window** to configure the target date, menu bar appearance, and launch at login.
- Easy to pass around: built from source in Xcode, distributed to teammates as a **DMG**.

## Non-goals

- No shared/team backend. Each person enters their own date; nothing is synced or sent anywhere.
- No serious features (job search tracking, handover checklists, calendar integration).
- No Mac App Store distribution.

## Anti-goals (would make it a failure even if it works)

- Network access, analytics, or anything that phones home. It's a joke about layoffs; it must not leak anything about who installed it.
- Humor that punches at specific people or the company by name. Jokes stay about the situation.

## Decided by the user

- **Surfaces:** menu bar item + desktop widget + settings window.
- **Settings window covers:** target (layoff) date, menu bar appearance, auto-start at login.
- **Menu bar default style:** emoji + short countdown, e.g. `💀 23d 4h`.
- **Widget:** medium size. Ticking clock (`23d 4:17:52`), red progress bar showing how much of the notice period has elapsed, and a rotating dark one-liner that changes daily (e.g. "Remember to push your branches.").
- **Per-user date:** each person enters their own layoff date; the DMG ships with nothing preset.
- **Distribution:** build from source in Xcode, package as DMG. The user will set up signing with a free Apple ID ("Personal Team") later.
- **Widget is a bonus on teammates' Macs:** from the DMG, the menu bar app must work fully on its own; the widget works where signing allows. Early in the build, run a quick test: install the DMG on a second Mac and check whether the widget appears and reads the settings. The result tells the team what to expect; it does not block the menu bar app.

## Builder's calls (made during brainstorming, user can override)

- **Menu bar style options** in settings: the default short style (`💀 23d 4h`) and the full ticking style (`23d 4:17:52`, which the user also considered; hours unpadded to match the widget's system timer, user decision 2026-10-22). The emoji is user-changeable (default 💀).
- **Layoff moment:** settings take a date and a time (default 17:00), in the Mac's local time zone. The countdown and "Goodbye" use that exact moment.
- **Storage fallback:** settings are written to the App Group when it is available and to the app's own storage otherwise, so the menu bar app never depends on the App Group. The widget shows a "Set your date in the app" state when it can't read shared settings.
- **Signing team is easy to change:** keep the team ID in one config file (xcconfig) and derive the App Group ID from it, so the user, or a teammate building from source, can switch accounts in one place.
- **Start date** setting (the day the layoff was announced), needed for the widget's progress bar. Default: the date the user first saves a layoff date.
- **Jokes:** built-in list of ~30 one-liners, picked deterministically by day so it changes once per day. Not user-editable in v1.
- **At zero:** menu bar shows `💀 Goodbye`; widget replaces the countdown with a farewell line. No negative/overtime counting.
- **First launch:** if no layoff date is set, open the settings window automatically; menu bar shows `💀 Set date`.
- **Signing:** project must build and run locally without a paid account. Signing team left as a setting to fill in later. Widgets require signing (and the app group shared with the widget extension), so expect the widget to need the Personal Team signing before it works on teammates' Macs. Teammates bypass Gatekeeper via System Settings › Privacy & Security › Open Anyway (right-click → Open no longer works on macOS 15+).
- **Shared DMG is unsigned (ad-hoc)** (user decision 2026-10-22): Personal Team signing would put the builder's Apple ID name and team ID in the signature. Personal Team signing is for the builder's own Mac only. If the widget can't read settings on teammates' Macs, the team gets the menu bar only; no separate in-widget date entry.
- **Past layoff moment at Save** shows `💀 Goodbye` immediately, no warning (user decision 2026-10-22).

## Constraints

- macOS desktop widgets require macOS 14 (Sonoma) or later; target macOS 14+.
- The app and widget extension must share settings (layoff date, start date, emoji), e.g. via an App Group.
- Widget timelines are not refreshed every second; the ticking clock must use the system's self-updating timer text rather than per-second timeline entries.
- Menu bar–only app (no Dock icon) apart from the settings window.

## Left to the builder

- Project structure, SwiftUI vs AppKit specifics, exact layout and colors (dark, red accent, matching the mockups in `.superpowers/brainstorm/`).
- Joke list wording, within the anti-goals.
- DMG packaging script/tooling.
- Contents of the menu bar dropdown when clicked (at minimum: full countdown, open settings, quit).
