import LayoffCore
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsForm(initial: model.settings)
    }
}

/// Edits draft seeded from settings when window opens. Only Save writes back.
private struct SettingsForm: View {
    @EnvironmentObject private var model: AppModel

    @State private var layoffDate: Date
    @State private var startDate: Date
    @State private var emoji: String
    @State private var style: MenuBarStyle
    @State private var openAtLogin = false
    @State private var loginNeedsApproval = false
    @State private var loginError: String?

    init(initial s: LayoffSettings) {
        _layoffDate = State(initialValue: s.layoffDate ?? LayoffSettings.defaultLayoffDate(now: .now, calendar: .current))
        _startDate = State(initialValue: s.startDate ?? .now)
        _emoji = State(initialValue: s.emoji)
        _style = State(initialValue: s.menuBarStyle)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Layoff") {
                    DatePicker("Layoff moment", selection: $layoffDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Announced on", selection: $startDate, displayedComponents: [.date])
                    Text("Times use this Mac's time zone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Menu bar") {
                    Picker("Style", selection: $style) {
                        ForEach(MenuBarStyle.allCases, id: \.self) { style in
                            Text(sampleTitle(style)).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextField("Emoji", text: $emoji)
                        .onSubmit { emoji = sanitizedEmoji }
                }
                Section("General") {
                    Toggle("Open at login", isOn: Binding(get: { openAtLogin }, set: setOpenAtLogin))
                    if loginNeedsApproval {
                        HStack {
                            Text("Approve in System Settings › Login Items")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Open System Settings") { LaunchAtLogin.openSystemSettings() }
                        }
                    }
                    if let loginError {
                        Text(loginError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            // Grouped Form is a scroll view; window already sizes to fit, so stop the elastic scroll and scroller.
            .scrollDisabled(true)

            HStack {
                MenuBarPreview(deadline: LayoffSettings.wholeMinute(layoffDate), style: style, emoji: sanitizedEmoji)
                Spacer()
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        // Login item can change in System Settings while window stays open or hidden.
        .onAppear(perform: refreshLoginState)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLoginState()
        }
        // Settings window is app's only regular window, so any key change means it came forward.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refreshLoginState()
        }
    }

    private var sanitizedEmoji: String { LayoffSettings.sanitizedEmoji(emoji) }

    /// 23d 4h 17m 52s, matching example titles used across app.
    private func sampleTitle(_ style: MenuBarStyle) -> String {
        CountdownFormatter.menuBarTitle(state: .counting(remaining: 2_002_672), style: style, emoji: sanitizedEmoji)
    }

    private func save() {
        emoji = sanitizedEmoji
        var s = model.settings
        s.emoji = emoji
        s.menuBarStyle = style
        // Start of day, so leftover time of day does not skew progress.
        s.startDate = Calendar.current.startOfDay(for: startDate)
        model.update(s.settingLayoffDate(layoffDate, now: .now))
    }

    private func setOpenAtLogin(_ on: Bool) {
        do {
            try LaunchAtLogin.set(on)
            loginError = nil
        } catch {
            loginError = error.localizedDescription
        }
        refreshLoginState()
    }

    /// Toggle follows system status, not requested value: failed call reverts it, pending approval keeps it on.
    private func refreshLoginState() {
        let status = LaunchAtLogin.status
        loginNeedsApproval = status == .requiresApproval
        openAtLogin = status == .enabled || loginNeedsApproval
    }
}

private struct MenuBarPreview: View {
    @EnvironmentObject private var ticker: Ticker
    let deadline: Date
    let style: MenuBarStyle
    let emoji: String

    var body: some View {
        MenuBarTitle(state: .make(deadline: deadline, now: ticker.now), style: style, emoji: emoji)
            .foregroundStyle(.secondary)
    }
}
