import Foundation

public enum Jokes {
    public static let all: [String] = [
        "Remember to push your branches.",
        "Your tickets will outlive you.",
        "Unsubscribe from the all-hands invite. Oh wait.",
        "Your TODO comments are someone else's problem now.",
        "Write the docs. Or don't. Who's checking?",
        "Your on-call rotation has a hole shaped like you.",
        "Every standup is a farewell tour.",
        "Technical debt is no longer your debt.",
        "Your last commit message: make it count.",
        "The build is red. Not your problem soon.",
        "Your password expires after you do.",
        "Merge conflicts are temporary. So are you.",
        "Your access badge is counting down too.",
        "Enjoy the free coffee while it lasts.",
        "Your 1:1s are now 0:1s.",
        "Somebody will inherit your bash aliases.",
        "Long-term roadmap? Define long.",
        "Your Q4 goals are now optional reading.",
        "Clean up your desktop. Both of them.",
        "Your code review comments will echo forever.",
        "The legacy code is now your legacy.",
        "Feedback is a gift. Severance is better.",
        "Reply-all while you still can. Or not.",
        "Your Friday deploys finally have no consequences.",
        "Knowledge transfer: a fancy word for goodbye.",
        "Your calendar is filling up with nothing.",
        "Rename your last branch to something poetic.",
        "Someone else gets your monitor now.",
        "That flaky test will miss you. Nobody else will.",
        "Out of office: permanently.",
    ]

    public static let farewell = "Goodbye. Hand in your laptop on the way out."

    /// Picks by local day so joke changes once per day at midnight, same in app and widget.
    public static func joke(for date: Date, calendar: Calendar) -> String {
        let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? .distantPast
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: epoch), to: calendar.startOfDay(for: date)).day ?? 0
        // Swift % keeps sign of dividend; dates before epoch need wrap to non-negative.
        let index = (days % all.count + all.count) % all.count
        return all[index]
    }
}
