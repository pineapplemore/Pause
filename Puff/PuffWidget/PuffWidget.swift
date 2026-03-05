//
//  PuffWidget.swift
//  PuffWidget
//
//  小号小组件：iOS 17+ 可交互时显示圆圈+、上方次数、3 个胶囊标签；否则只显示圆圈=与当日次数。
//

import WidgetKit
import SwiftUI

private let kAppGroupSuite = "group.com.puff.app"
private let kRecordsKey = "puff_records"
private let kWidgetFavoriteTagIds = "widget_favorite_tag_ids"
private let kWidgetFavoriteTagLabels = "widget_favorite_tag_labels"
private let kPuffAppLanguageIsChinese = "Puff.appLanguageIsChinese"

/// 主应用青绿主题色（与 Puff 一致）
private var widgetAccent: Color { Color(red: 0.357, green: 0.604, blue: 0.545) }

private struct WidgetPuffRecord: Codable {
    let id: UUID
    let timestamp: Date
    var typeIds: [String]
}

private func loadRecords() -> [WidgetPuffRecord] {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    guard let data = suite.data(forKey: kRecordsKey),
          let list = try? JSONDecoder().decode([WidgetPuffRecord].self, from: data) else {
        return []
    }
    return list
}

private func todayCount() -> Int {
    let cal = Calendar.current
    let today = Date()
    return loadRecords().filter { cal.isDate($0.timestamp, inSameDayAs: today) }.count
}

/// 当日各标签出现次数，按次数降序
private func todayTagDistribution() -> [(tagId: String, count: Int)] {
    let cal = Calendar.current
    let today = Date()
    let list = loadRecords().filter { cal.isDate($0.timestamp, inSameDayAs: today) }
    var dict: [String: Int] = [:]
    for rec in list {
        for id in rec.typeIds {
            dict[id, default: 0] += 1
        }
    }
    return dict.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
}

private func widgetFavoriteTagIds() -> [String] {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    return suite.stringArray(forKey: kWidgetFavoriteTagIds) ?? []
}

private func widgetFavoriteTagLabels() -> [String] {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    return suite.stringArray(forKey: kWidgetFavoriteTagLabels) ?? []
}

/// 与主 App 用户选择一致，供小组件名称与描述使用
private func widgetAppLanguageIsChinese() -> Bool {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    if suite.object(forKey: kPuffAppLanguageIsChinese) == nil { return true }
    return suite.bool(forKey: kPuffAppLanguageIsChinese)
}

/// rawValue → 显示名（与主 App 一致）；用于 3 个常用标签时优先用 labels
private func widgetTagDisplayName(tagId: String, at index: Int, labels: [String]) -> String {
    if index < labels.count, !labels[index].isEmpty { return labels[index] }
    return widgetDisplayNameForTagId(tagId)
}

/// 任意 tagId 的显示名（当日统计用）
private func widgetDisplayNameForTagId(_ tagId: String) -> String {
    if tagId.hasPrefix("custom:") { return String(tagId.dropFirst(7)) }
    switch tagId {
    case "臭屁": return "巨臭屁"
    case "突突突屁": return "连环屁"
    case "闷屁", "响屁", "热屁", "寒屁", "吃辣后", "喝冰水后": return tagId
    default: return tagId
    }
}

struct PuffWidgetEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let favoriteTagIds: [String]
    let favoriteTagLabels: [String]
    let todayTagDistribution: [(tagId: String, count: Int)]
}

struct PuffWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PuffWidgetEntry {
        PuffWidgetEntry(date: Date(), todayCount: 0, favoriteTagIds: [], favoriteTagLabels: [], todayTagDistribution: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PuffWidgetEntry) -> Void) {
        completion(PuffWidgetEntry(date: Date(), todayCount: todayCount(), favoriteTagIds: widgetFavoriteTagIds(), favoriteTagLabels: widgetFavoriteTagLabels(), todayTagDistribution: todayTagDistribution()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PuffWidgetEntry>) -> Void) {
        let entry = PuffWidgetEntry(date: Date(), todayCount: todayCount(), favoriteTagIds: widgetFavoriteTagIds(), favoriteTagLabels: widgetFavoriteTagLabels(), todayTagDistribution: todayTagDistribution())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

/// 当日标签统计文案（如 巨臭屁 x3, 闷屁 x2）
private func tagStatsLines(_ distribution: [(tagId: String, count: Int)]) -> [String] {
    distribution.map { "\(widgetDisplayNameForTagId($0.tagId)) x\($0.count)" }
}

struct PuffWidgetSmallView: View {
    var entry: PuffWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            if #available(iOS 17.0, *) {
                interactiveSmallView
            } else {
                nonInteractiveSmallView
            }
        case .systemMedium:
            if #available(iOS 17.0, *) {
                interactiveMediumView
            } else {
                nonInteractiveMediumView
            }
        default:
            EmptyView()
        }
    }
    
    /// iOS 17+ 小号：小屁股图，下方「X 次」，3 个胶囊标签
    @available(iOS 17.0, *)
    private var interactiveSmallView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Link(destination: URL(string: "puff://record")!) {
                Image("WidgetPuffIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            HStack(spacing: 2) {
                Text("\(entry.todayCount)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(widgetAccent)
                Text("次")
                    .font(.caption)
                    .foregroundColor(widgetAccent)
            }
            .padding(.top, 4)
            if !entry.favoriteTagIds.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<min(3, entry.favoriteTagIds.count), id: \.self) { i in
                        Link(destination: URL(string: "puff://record?tag=\(entry.favoriteTagIds[i].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? entry.favoriteTagIds[i])")!) {
                            Text(widgetTagDisplayName(tagId: entry.favoriteTagIds[i], at: i, labels: entry.favoriteTagLabels))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(widgetAccent)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().stroke(widgetAccent, lineWidth: 1.2))
                        }
                    }
                }
                .padding(.top, 6)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 12)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
    
    /// 非 iOS 17 小号：左半总次数+当日标签统计（最多5条），右半小屁股图标
    private var nonInteractiveSmallView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 2) {
                    Text("\(entry.todayCount)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(widgetAccent)
                    Text("次")
                        .font(.subheadline)
                        .foregroundColor(widgetAccent)
                }
                if !entry.todayTagDistribution.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<min(5, entry.todayTagDistribution.count), id: \.self) { i in
                            Text(tagStatsLines(entry.todayTagDistribution)[i])
                                .font(.caption)
                                .foregroundColor(widgetAccent)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .padding(.top, 12)
            Spacer(minLength: 4)
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 12)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
    
    /// iOS 17+ 中号：左侧 3 胶囊标签，中间小屁股图，右侧总次数+当日标签统计
    @available(iOS 17.0, *)
    private var interactiveMediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if !entry.favoriteTagIds.isEmpty {
                    ForEach(0..<min(3, entry.favoriteTagIds.count), id: \.self) { i in
                        Link(destination: URL(string: "puff://record?tag=\(entry.favoriteTagIds[i].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? entry.favoriteTagIds[i])")!) {
                            Text(widgetTagDisplayName(tagId: entry.favoriteTagIds[i], at: i, labels: entry.favoriteTagLabels))
                                .font(.caption)
                                .foregroundColor(widgetAccent)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().stroke(widgetAccent, lineWidth: 1.2))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Link(destination: URL(string: "puff://record")!) {
                Image("WidgetPuffIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 2) {
                    Text("\(entry.todayCount)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(widgetAccent)
                    Text("次")
                        .font(.caption)
                        .foregroundColor(widgetAccent)
                }
                if !entry.todayTagDistribution.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<min(5, entry.todayTagDistribution.count), id: \.self) { i in
                            Text(tagStatsLines(entry.todayTagDistribution)[i])
                                .font(.caption)
                                .foregroundColor(widgetAccent.opacity(0.9))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
    
    /// 非 iOS 17 中号：总次数 + 当日标签统计（最多5条）
    private var nonInteractiveMediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text("\(entry.todayCount)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(widgetAccent)
                Text("次")
                    .font(.subheadline)
                    .foregroundColor(widgetAccent)
            }
            if !entry.todayTagDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(0..<min(5, entry.todayTagDistribution.count), id: \.self) { i in
                        Text(tagStatsLines(entry.todayTagDistribution)[i])
                            .font(.caption)
                            .foregroundColor(widgetAccent)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
}

@main
struct PuffWidgetBundle: WidgetBundle {
    var body: some Widget {
        PuffWidget()
    }
}

struct PuffWidget: Widget {
    let kind: String = "PuffWidget"
    
    var body: some WidgetConfiguration {
        let isChinese = widgetAppLanguageIsChinese()
        return StaticConfiguration(kind: kind, provider: PuffWidgetProvider()) { entry in
            PuffWidgetSmallView(entry: entry)
        }
        .configurationDisplayName(isChinese ? "放屁记录" : "Puff Diary")
        .description(isChinese ? "今日次数与类型统计" : "Today's count and tag stats")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
