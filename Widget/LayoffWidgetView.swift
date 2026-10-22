import LayoffCore
import SwiftUI
import WidgetKit

struct LayoffWidgetView: View {
    let entry: LayoffEntry

    private static let background = Color(red: 0.11, green: 0.11, blue: 0.12)
    private static let accent = Color(red: 1, green: 0.27, blue: 0.23)

    private var emoji: String { entry.settings?.emoji ?? LayoffSettings.defaultEmoji }

    var body: some View {
        content
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(Self.background, for: .widget)
    }

    // Verbatim text keeps ASCII digits and the emoji as-is in every locale, matching the menu bar.
    @ViewBuilder
    private var content: some View {
        if let settings = entry.settings, let deadline = settings.layoffDate {
            if case .counting(let remaining) = CountdownState.make(deadline: deadline, now: entry.date) {
                counting(days: CountdownFormatter.parts(remaining).days, start: settings.startDate, deadline: deadline)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "\(emoji) Goodbye")
                        .font(.system(size: 30, weight: .bold))
                    Text(Jokes.farewell)
                        .font(.system(size: 13))
                        .opacity(0.8)
                }
            }
        } else {
            Text(verbatim: "\(emoji) Set your date in the app")
                .font(.title3.bold())
        }
    }

    private func counting(days: Int, start: Date?, deadline: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "\(emoji) TIME LEFT AT THE COMPANY")
                .font(.caption)
                .opacity(0.6)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(verbatim: "\(days)d ")
                // Timer text takes all offered width; widest clock string pins it so row stays leading.
                Text(verbatim: "00:00:00")
                    .hidden()
                    .overlay(alignment: .leading) {
                        Text(timerInterval: entry.date...WidgetSchedule.dayBoundary(before: deadline, now: entry.date),
                             countsDown: true)
                    }
            }
            .font(.system(size: 30, weight: .bold))
            .monospacedDigit()
            .lineLimit(1)
            progress(start: start, deadline: deadline)
                .tint(Self.accent)
                .widgetAccentable()
            Text(verbatim: "\u{201C}\(entry.joke)\u{201D}")
                .font(.system(size: 13))
                .lineLimit(2)
                .opacity(0.8)
        }
    }

    @ViewBuilder
    private func progress(start: Date?, deadline: Date) -> some View {
        if let start, start < deadline {
            ProgressView(timerInterval: start...deadline, countsDown: false) {} currentValueLabel: {}
        } else {
            // No usable notice period start: whole bar counts as gone.
            ProgressView(value: 1)
        }
    }
}

#Preview("Counting", as: .systemMedium) {
    LayoffWidget()
} timeline: {
    LayoffEntry.sample(now: .now)
}

#Preview("Day rollover", as: .systemMedium) {
    LayoffWidget()
} timeline: {
    // Boundary 5 s out; second entry mirrors provider's boundary + 1 s entry.
    let now = Date.now
    let settings = LayoffSettings(layoffDate: now.addingTimeInterval(2 * 86_400 + 5),
                                  startDate: now.addingTimeInterval(-10 * 86_400))
    LayoffEntry(date: now, settings: settings)
    LayoffEntry(date: now.addingTimeInterval(6), settings: settings)
}

#Preview("Goodbye", as: .systemMedium) {
    LayoffWidget()
} timeline: {
    let now = Date.now
    LayoffEntry(date: now, settings: LayoffSettings(layoffDate: now.addingTimeInterval(-60)))
}

#Preview("Not set", as: .systemMedium) {
    LayoffWidget()
} timeline: {
    LayoffEntry(date: .now, settings: nil)
}
