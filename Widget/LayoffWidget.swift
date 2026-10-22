import SwiftUI
import WidgetKit

struct LayoffEntry: TimelineEntry {
    let date: Date
}

struct LayoffProvider: TimelineProvider {
    func placeholder(in context: Context) -> LayoffEntry { LayoffEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (LayoffEntry) -> Void) {
        completion(LayoffEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LayoffEntry>) -> Void) {
        completion(Timeline(entries: [LayoffEntry(date: .now)], policy: .never))
    }
}

@main
struct LayoffWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LayoffWidget", provider: LayoffProvider()) { _ in
            Text("💀")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Layoff Countdown")
        .supportedFamilies([.systemMedium])
    }
}
