import LayoffCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    /// Model ticks every second. Form takes model as plain value so SwiftUI skips its body on ticks
    /// and pickers/text field are not redrawn mid-edit; only preview line observes clock.
    var body: some View {
        SettingsForm(model: model)
    }
}

private struct SettingsForm: View {
    let model: AppModel

    @State private var layoffDate: Date
    @State private var startDate: Date
    @State private var emoji: String
    @State private var style: MenuBarStyle
    @State private var openAtLogin = LaunchAtLogin.isEnabled || LaunchAtLogin.needsApproval
    @State private var loginNeedsApproval = LaunchAtLogin.needsApproval
    @State private var loginError: String?

    init(model: AppModel) {
        self.model = model
        let s = model.settings
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

            HStack {
                MenuBarPreview(deadline: layoffMoment, style: style, emoji: sanitizedEmoji)
                Spacer()
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        // User may approve login item in System Settings while window stays open.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginNeedsApproval = LaunchAtLogin.needsApproval
            openAtLogin = LaunchAtLogin.isEnabled || loginNeedsApproval
        }
    }

    private var sanitizedEmoji: String { LayoffSettings.sanitizedEmoji(emoji) }

    /// Seconds zeroed: picker keeps seconds from its initial value, and moment off whole minute
    /// would flip menu bar out of step with widget timer.
    private var layoffMoment: Date {
        Calendar.current.dateInterval(of: .minute, for: layoffDate)?.start ?? layoffDate
    }

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
        model.update(s.settingLayoffDate(layoffMoment, now: .now))
    }

    private func setOpenAtLogin(_ on: Bool) {
        do {
            try LaunchAtLogin.set(on)
            loginError = nil
        } catch {
            loginError = error.localizedDescription
        }
        // Status, not requested value: failed call reverts toggle, pending approval keeps it on.
        loginNeedsApproval = LaunchAtLogin.needsApproval
        openAtLogin = LaunchAtLogin.isEnabled || loginNeedsApproval
    }
}

private struct MenuBarPreview: View {
    @EnvironmentObject private var model: AppModel
    let deadline: Date
    let style: MenuBarStyle
    let emoji: String

    var body: some View {
        Text(CountdownFormatter.menuBarTitle(state: .make(deadline: deadline, now: model.now),
                                             style: style, emoji: emoji))
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}
