import AppIntents
import LayoffCore
import SwiftUI
import WidgetKit

struct LayoffEntry: TimelineEntry {
    let date: Date
    /// Nil when no widget date is set and settings live outside App Group, so widget can't see them.
    let settings: LayoffSettings?
    let joke: String

    init(date: Date, settings: LayoffSettings?) {
        self.date = date
        self.settings = settings
        joke = Jokes.joke(for: date, calendar: .current)
    }

    /// Gallery sample: 23d 4:17:52 left, about two thirds of notice period gone.
    static func sample(now: Date) -> LayoffEntry {
        let deadline = now.addingTimeInterval(23 * 86_400 + 4 * 3_600 + 17 * 60 + 52)
        let settings = LayoffSettings(layoffDate: deadline, startDate: deadline.addingTimeInterval(-72 * 86_400))
        return LayoffEntry(date: now, settings: settings)
    }
}

/// Edit Widget shows dates without a time, so the hour is its own field.
enum LayoffHour: Int, AppEnum {
    case h00 = 0
    case h01 = 1
    case h02 = 2
    case h03 = 3
    case h04 = 4
    case h05 = 5
    case h06 = 6
    case h07 = 7
    case h08 = 8
    case h09 = 9
    case h10 = 10
    case h11 = 11
    case h12 = 12
    case h13 = 13
    case h14 = 14
    case h15 = 15
    case h16 = 16
    case h17 = 17
    case h18 = 18
    case h19 = 19
    case h20 = 20
    case h21 = 21
    case h22 = 22
    case h23 = 23

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Hour"
    static var caseDisplayRepresentations: [LayoffHour: DisplayRepresentation] = [
        .h00: "00:00",
        .h01: "01:00",
        .h02: "02:00",
        .h03: "03:00",
        .h04: "04:00",
        .h05: "05:00",
        .h06: "06:00",
        .h07: "07:00",
        .h08: "08:00",
        .h09: "09:00",
        .h10: "10:00",
        .h11: "11:00",
        .h12: "12:00",
        .h13: "13:00",
        .h14: "14:00",
        .h15: "15:00",
        .h16: "16:00",
        .h17: "17:00",
        .h18: "18:00",
        .h19: "19:00",
        .h20: "20:00",
        .h21: "21:00",
        .h22: "22:00",
        .h23: "23:00",
    ]
}

struct LayoffWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Layoff Countdown"
    static var description = IntentDescription("Set your date here when the widget can't read the app's settings.")

    @Parameter(title: "Layoff date", kind: .date)
    var layoffDate: Date?

    @Parameter(title: "Layoff time", default: .h17)
    var layoffHour: LayoffHour

    @Parameter(title: "Notice started", kind: .date)
    var startDate: Date?
}

struct LayoffProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LayoffEntry { .sample(now: .now) }

    func snapshot(for configuration: LayoffWidgetIntent, in context: Context) async -> LayoffEntry {
        context.isPreview ? .sample(now: .now) : LayoffEntry(date: .now, settings: Self.settings(configuration))
    }

    func timeline(for configuration: LayoffWidgetIntent, in context: Context) async -> Timeline<LayoffEntry> {
        let settings = Self.settings(configuration)
        let dates = WidgetSchedule.entryDates(now: .now, deadline: settings?.layoffDate, calendar: .current)
        let entries = dates.map { LayoffEntry(date: $0, settings: settings) }
        return Timeline(entries: entries, policy: .after(dates.last ?? .now))
    }

    private static func settings(_ configuration: LayoffWidgetIntent) -> LayoffSettings? {
        LayoffSettings.widget(layoffDay: configuration.layoffDate, hour: configuration.layoffHour.rawValue,
                              startDay: configuration.startDate, shared: sharedSettings(), calendar: .current)
    }

    /// Standard defaults belong to widget's own sandbox, not app's, so only App Group store counts.
    private static func sharedSettings() -> LayoffSettings? {
        let store = SettingsStore.make(appGroupID: AppGroup.current)
        return store.usesAppGroup ? store.load() : nil
    }
}

@main
struct LayoffWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LayoffWidget", intent: LayoffWidgetIntent.self, provider: LayoffProvider()) { entry in
            LayoffWidgetView(entry: entry)
        }
        .configurationDisplayName("Layoff Countdown")
        .description("Time left at the company.")
        .supportedFamilies([.systemMedium])
    }
}
