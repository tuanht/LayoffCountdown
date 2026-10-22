import LayoffCore
import SwiftUI
import WidgetKit

struct LayoffEntry: TimelineEntry {
    let date: Date
    /// Nil when settings live outside App Group, so widget can't see them.
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

struct LayoffProvider: TimelineProvider {
    func placeholder(in context: Context) -> LayoffEntry { .sample(now: .now) }

    func getSnapshot(in context: Context, completion: @escaping (LayoffEntry) -> Void) {
        completion(context.isPreview ? .sample(now: .now) : LayoffEntry(date: .now, settings: Self.sharedSettings()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LayoffEntry>) -> Void) {
        let settings = Self.sharedSettings()
        let dates = WidgetSchedule.entryDates(now: .now, deadline: settings?.layoffDate, calendar: .current)
        let entries = dates.map { LayoffEntry(date: $0, settings: settings) }
        completion(Timeline(entries: entries, policy: .after(dates.last ?? .now)))
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
        StaticConfiguration(kind: "LayoffWidget", provider: LayoffProvider()) { entry in
            LayoffWidgetView(entry: entry)
        }
        .configurationDisplayName("Layoff Countdown")
        .description("Time left at the company.")
        .supportedFamilies([.systemMedium])
    }
}
