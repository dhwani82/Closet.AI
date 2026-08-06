//
//  TodayOutfitWidget.swift
//  ClosetAIWidget
//
//  Created by Dhwani Chauhan.
//

import WidgetKit
import SwiftUI

struct TodayOutfitEntry: TimelineEntry {
    let date: Date
    let snapshot: TodayOutfitSnapshot?
}

struct TodayOutfitProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayOutfitEntry {
        TodayOutfitEntry(
            date: .now,
            snapshot: TodayOutfitSnapshot(
                name: "Casual Friday",
                pieces: ["Navy top", "Gray jeans"],
                reasoning: "Easy everyday layers.",
                updatedAt: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayOutfitEntry) -> Void) {
        completion(TodayOutfitEntry(date: .now, snapshot: TodayOutfitStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayOutfitEntry>) -> Void) {
        let entry = TodayOutfitEntry(date: .now, snapshot: TodayOutfitStore.load())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TodayOutfitWidget: Widget {
    let kind = "TodayOutfitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayOutfitProvider()) { entry in
            TodayOutfitWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Outfit")
        .description("Shows your latest Closet.AI outfit suggestion.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayOutfitWidgetView: View {
    var entry: TodayOutfitEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            outfitContent(snapshot)
        } else {
            emptyContent
        }
    }

    private func outfitContent(_ snapshot: TodayOutfitSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Today", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(snapshot.name)
                .font(family == .systemSmall ? .subheadline.weight(.semibold) : .headline)
                .lineLimit(2)

            if family == .systemMedium {
                Text(snapshot.pieces.prefix(3).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(snapshot.reasoning)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if let first = snapshot.pieces.first {
                Text(first)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
            Text("No outfit yet")
                .font(.subheadline.weight(.semibold))
            Text("Generate outfits in Closet.AI")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall) {
    TodayOutfitWidget()
} timeline: {
    TodayOutfitEntry(date: .now, snapshot: nil)
    TodayOutfitEntry(
        date: .now,
        snapshot: TodayOutfitSnapshot(
            name: "Smart Casual",
            pieces: ["Beige top", "Black trousers"],
            reasoning: "Clean contrast for the day.",
            updatedAt: .now
        )
    )
}
