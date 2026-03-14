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
    
    /// 次数+单位一行文案，避免中号左侧 "0 times" 换行
    private var countAndUnitText: String {
        let unit = widgetAppLanguageIsChinese() ? "次" : "times"
        return "\(entry.todayCount) \(unit)"
    }
    
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
    
    /// iOS 17+ 小号：屁股图中间靠上，次数在屁股图下方
    @available(iOS 17.0, *)
    private var interactiveSmallView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            widgetTapTargetSmall
            HStack(spacing: 4) {
                Text("\(entry.todayCount)")
                    .font(.title.weight(.bold))
                    .foregroundColor(widgetAccent)
                Text(widgetAppLanguageIsChinese() ? "次" : " times")
                    .font(.title3.weight(.medium))
                    .foregroundColor(widgetAccent)
            }
            .padding(.top, 6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
    
    @available(iOS 17.0, *)
    private var widgetTapTargetSmall: AnyView {
        #if canImport(AppIntents)
        return AnyView(Button(intent: RecordPuffIntent()) {
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
        }.buttonStyle(.plain))
        #else
        return AnyView(Link(destination: URL(string: "puff://record")!) {
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
        })
        #endif
    }
    
    /// 非 iOS 17 小号：与交互版一致——屁股图中间靠上，次数在屁股图下方
    private var nonInteractiveSmallView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
            HStack(spacing: 4) {
                Text("\(entry.todayCount)")
                    .font(.title.weight(.bold))
                    .foregroundColor(widgetAccent)
                Text(widgetAppLanguageIsChinese() ? "次" : " times")
                    .font(.title3.weight(.medium))
                    .foregroundColor(widgetAccent)
            }
            .padding(.top, 6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
    
    /// iOS 17+ 中号：左侧次数，中间屁股图（点图 +1），右侧 3 个标签按键
    @available(iOS 17.0, *)
    private var interactiveMediumView: some View {
        HStack(alignment: .center, spacing: 14) {
            // 左侧：今日次数（留足边距，不贴边）
            VStack(alignment: .leading, spacing: 4) {
                Text(countAndUnitText)
                    .font(.title2.weight(.bold))
                    .foregroundColor(widgetAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .frame(width: 64, alignment: .leading)
            .padding(.leading, 4)
            // 中间：屁股图（点击 +1）
            widgetTapTargetMedium
                .frame(minWidth: 100)
            Spacer(minLength: 0)
            // 右侧：3 个常用标签（点击 = 给最后一条记录加标签）
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(0..<min(3, entry.favoriteTagIds.count), id: \.self) { i in
                    widgetMediumTagButton(tagId: entry.favoriteTagIds[i], label: widgetTagDisplayName(tagId: entry.favoriteTagIds[i], at: i, labels: entry.favoriteTagLabels))
                }
                Spacer(minLength: 0)
            }
            .frame(width: 76, alignment: .trailing)
            .padding(.trailing, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(
            Image("WidgetBackground")
                .resizable()
                .scaledToFill()
                .clipped()
        )
    }
    
    @available(iOS 17.0, *)
    private func widgetMediumTagButton(tagId: String, label: String) -> some View {
        Group {
            #if canImport(AppIntents)
            Button(intent: AddTagToLastRecordIntent(tagId: tagId)) {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(widgetAccent.opacity(0.25))
                    .foregroundColor(widgetAccent)
                    .clipShape(Capsule())
            }.buttonStyle(.plain)
            #else
            Link(destination: URL(string: "puff://record?tag=\(tagId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tagId)")!) {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(widgetAccent.opacity(0.25))
                    .foregroundColor(widgetAccent)
                    .clipShape(Capsule())
            }
            #endif
        }
    }
    
    /// 中号中间：仅屁股图，点击 +1（次数已移到左侧显示）
    @available(iOS 17.0, *)
    private var widgetTapTargetMedium: AnyView {
        #if canImport(AppIntents)
        return AnyView(Button(intent: RecordPuffIntent()) {
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
        }.buttonStyle(.plain))
        #else
        return AnyView(Link(destination: URL(string: "puff://record")!) {
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
        })
        #endif
    }
    
    /// 非 iOS 17 中号：左侧次数（留边距），中间屁股图，右侧当日标签统计（最多5条）
    private var nonInteractiveMediumView: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(countAndUnitText)
                    .font(.title2.weight(.bold))
                    .foregroundColor(widgetAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .frame(width: 64, alignment: .leading)
            .padding(.leading, 4)
            Image("WidgetPuffIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
            Spacer(minLength: 0)
            if !entry.todayTagDistribution.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(0..<min(5, entry.todayTagDistribution.count), id: \.self) { i in
                        Text(tagStatsLines(entry.todayTagDistribution)[i])
                            .font(.caption)
                            .foregroundColor(widgetAccent.opacity(0.9))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
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
    
    /// 非 iOS 17 仅提供小号；iOS 17+ 提供小号与中号
    private static var supportedFamilies: [WidgetFamily] {
        if #available(iOS 17.0, *) {
            return [.systemSmall, .systemMedium]
        } else {
            return [.systemSmall]
        }
    }
    
    var body: some WidgetConfiguration {
        // 与主 App 语言一致：从 App Group 读取，App 英文则弹窗显示英文，中文则显示中文
        let isChinese = widgetAppLanguageIsChinese()
        return StaticConfiguration(kind: kind, provider: PuffWidgetProvider()) { entry in
            PuffWidgetSmallView(entry: entry)
        }
        .configurationDisplayName(isChinese ? "放屁记录" : "Puff Diary")
        .description(isChinese ? "今日次数与类型统计" : "Today's count and tag stats")
        .supportedFamilies(Self.supportedFamilies)
    }
}
