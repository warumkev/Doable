//
//  DoableWidget.swift
//  DoableWidget
//
//  Created by Kevin Tamme on 14.10.25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), incompleteTodosCount: 0, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), incompleteTodosCount: 0, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let incompleteTodosCount = fetchIncompleteTodosCount()

        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, incompleteTodosCount: incompleteTodosCount, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    private func fetchIncompleteTodosCount() -> Int {
        // Replace with actual SwiftData fetch logic
        // Example: Fetch todos where isComplete == false
        return 0 // Placeholder
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let incompleteTodosCount: Int
    let configuration: ConfigurationAppIntent
}

struct DoableWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            Text("You have")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("\(entry.incompleteTodosCount)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)

            Text("open to-dos.")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct DoableWidget: Widget {
    let kind: String = "DoableWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            DoableWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    DoableWidget()
} timeline: {
    SimpleEntry(date: .now, incompleteTodosCount: 5, configuration: .smiley)
    SimpleEntry(date: .now, incompleteTodosCount: 3, configuration: .starEyes)
}
