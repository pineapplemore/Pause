//
//  PuffWidget.swift
//  PauseWidget
//
//  仅小号小组件：1～4 个方形按键。iOS 17+ 可点击记录；非 iOS 17 按键中间显示当日次数。
//

import WidgetKit
import SwiftUI

private let kAppGroupSuite = "group.com.pause.app"
private let kRecordsKey = "pause_records"
private let kBehaviorNamesKey = "Pause.behaviorNames"
private let kPauseAppLanguageIsChinese = "Pause.appLanguageIsChinese"
private let kShowInitialOnWidgetKey = "Pause.showInitialOnWidget"
private let kWidgetBehaviorInitialsKey = "Pause.widgetBehaviorInitials"
private let kBehaviorIds = ["b1", "b2", "b3", "b4"]

/// 与 app 一致的莫兰迪色（1～4 个行为）
private let kMorandiColors: [Color] = [
    Color(red: 0.45, green: 0.62, blue: 0.58),
    Color(red: 0.48, green: 0.54, blue: 0.72),
    Color(red: 0.70, green: 0.52, blue: 0.56),
    Color(red: 0.52, green: 0.64, blue: 0.48)
]
private let kMorandiDarkColors: [Color] = [
    Color(red: 0.38, green: 0.52, blue: 0.50),
    Color(red: 0.38, green: 0.44, blue: 0.60),
    Color(red: 0.58, green: 0.42, blue: 0.46),
    Color(red: 0.42, green: 0.52, blue: 0.40)
]
private func widgetMorandi(at index: Int) -> Color { kMorandiColors[index % kMorandiColors.count] }
private func widgetMorandiDark(at index: Int) -> Color { kMorandiDarkColors[index % kMorandiDarkColors.count] }

private struct WidgetPuffRecord: Codable {
    let id: UUID
    let timestamp: Date
    var typeIds: [String]
    var recordedBehaviorName: String?
}

private func loadRecords() -> [WidgetPuffRecord] {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    guard let data = suite.data(forKey: kRecordsKey),
          let list = try? JSONDecoder().decode([WidgetPuffRecord].self, from: data) else {
        return []
    }
    return list
}

private func widgetBehaviorNames() -> [String] {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    let stored = suite.stringArray(forKey: kBehaviorNamesKey) ?? []
    if stored.isEmpty {
        let isChinese = suite.object(forKey: kPauseAppLanguageIsChinese) == nil ? true : suite.bool(forKey: kPauseAppLanguageIsChinese)
        return [isChinese ? "咬指甲" : "Nail biting"]
    }
    return stored
}

/// 与 app 同步：显示当前 app 配置的 1～4 个行为
private func widgetBehaviorIds() -> [String] {
    let names = widgetBehaviorNames()
    return Array(kBehaviorIds.prefix(names.count))
}

/// 与 App 内语言一致：App 切到英文后小组件弹出页等均显示英文
private func widgetAppLanguageIsChinese() -> Bool {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    guard suite.object(forKey: kPauseAppLanguageIsChinese) != nil else { return true }
    return suite.bool(forKey: kPauseAppLanguageIsChinese)
}

private func widgetShowInitialOnWidget() -> Bool {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    return suite.bool(forKey: kShowInitialOnWidgetKey)
}

private func widgetBehaviorInitials() -> [String] {
    let suite = UserDefaults(suiteName: kAppGroupSuite) ?? UserDefaults.standard
    let list = suite.stringArray(forKey: kWidgetBehaviorInitialsKey) ?? []
    return (0..<4).map { i in
        i < list.count ? String(list[i].prefix(1)) : ""
    }
}

/// 当日各行为 id 的计数（顺序与 widget 显示的 1～4 个一致）
private func todayCountPerBehavior() -> [String: Int] {
    let cal = Calendar.current
    let today = Date()
    let list = loadRecords().filter { cal.isDate($0.timestamp, inSameDayAs: today) }
    var dict: [String: Int] = [:]
    for rec in list {
        for id in rec.typeIds where kBehaviorIds.contains(id) {
            dict[id, default: 0] += 1
        }
    }
    return dict
}

struct PuffWidgetEntry: TimelineEntry {
    let date: Date
    let behaviorIds: [String]
    let behaviorLabels: [String]
    let todayCountPerId: [String: Int]
    let showInitialOnWidget: Bool
    let behaviorInitials: [String]
}

struct PuffWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PuffWidgetEntry {
        let ids = widgetBehaviorIds()
        let labels = widgetBehaviorNames()
        return PuffWidgetEntry(date: Date(), behaviorIds: ids, behaviorLabels: labels, todayCountPerId: [:], showInitialOnWidget: false, behaviorInitials: widgetBehaviorInitials())
    }

    func getSnapshot(in context: Context, completion: @escaping (PuffWidgetEntry) -> Void) {
        let ids = widgetBehaviorIds()
        let labels = widgetBehaviorNames()
        let counts = todayCountPerBehavior()
        completion(PuffWidgetEntry(date: Date(), behaviorIds: ids, behaviorLabels: labels, todayCountPerId: counts, showInitialOnWidget: widgetShowInitialOnWidget(), behaviorInitials: widgetBehaviorInitials()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PuffWidgetEntry>) -> Void) {
        let ids = widgetBehaviorIds()
        let labels = widgetBehaviorNames()
        let counts = todayCountPerBehavior()
        let entry = PuffWidgetEntry(date: Date(), behaviorIds: ids, behaviorLabels: labels, todayCountPerId: counts, showInitialOnWidget: widgetShowInitialOnWidget(), behaviorInitials: widgetBehaviorInitials())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct PuffWidgetSmallView: View {
    var entry: PuffWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallContent
        case .systemMedium, .systemLarge, .systemExtraLarge:
            smallContent
        @unknown default:
            smallContent
        }
    }

    private var smallContent: some View {
        let n = entry.behaviorIds.count
        let side = widgetButtonSize(count: n)
        return ZStack {
            Color(.systemBackground)
            if n == 1 {
                oneButtonLayout(side: side)
            } else if n == 2 {
                twoButtonLayout(side: side)
            } else {
                gridLayout(side: side)
            }
        }
    }

    private func oneButtonLayout(side: CGFloat) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            widgetBehaviorButton(index: 0, side: side)
            Spacer(minLength: 0)
        }
    }

    private func twoButtonLayout(side: CGFloat) -> some View {
        let spacing: CGFloat = 4
        return HStack(spacing: spacing) {
            Spacer(minLength: 0)
            widgetBehaviorButton(index: 0, side: side)
            widgetBehaviorButton(index: 1, side: side)
            Spacer(minLength: 0)
        }
    }

    private func gridLayout(side: CGFloat) -> some View {
        let cols = 2
        let spacing: CGFloat = 3
        let rows = (entry.behaviorIds.count + cols - 1) / cols
        let contentWidth = CGFloat(cols) * side + CGFloat(cols - 1) * spacing
        let content = VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * cols + col
                        if idx < entry.behaviorIds.count {
                            widgetBehaviorButton(index: idx, side: side)
                        } else {
                            Color.clear.frame(width: side, height: side)
                        }
                    }
                }
            }
        }
        .frame(width: contentWidth, alignment: .leading)
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func widgetBehaviorButton(index: Int, side: CGFloat) -> some View {
        let id = entry.behaviorIds[index]
        let label = index < entry.behaviorLabels.count ? entry.behaviorLabels[index] : id
        let count = entry.todayCountPerId[id] ?? 0

        let initial: String = entry.showInitialOnWidget && index < entry.behaviorInitials.count && !entry.behaviorInitials[index].isEmpty ? entry.behaviorInitials[index] : ""
        #if !NO_APP_INTENTS && canImport(AppIntents)
        if #available(iOS 17.0, *) {
            Button(intent: RecordPuffIntent(behaviorId: id)) {
                widgetButtonContent(label: label, count: count, side: side, interactive: true, colorIndex: index, initial: initial)
            }
            .buttonStyle(.plain)
        } else {
            widgetButtonContent(label: label, count: count, side: side, interactive: false, colorIndex: index, initial: initial)
        }
        #else
        widgetButtonContent(label: label, count: count, side: side, interactive: false, colorIndex: index, initial: initial)
        #endif
    }

    private func widgetButtonContent(label: String, count: Int, side: CGFloat, interactive: Bool, colorIndex: Int, initial: String = "") -> some View {
        let imageName = "BehaviorButtonIcon\(colorIndex + 1)"
        return Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: side, height: side)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .center) {
                // 小组件只显示数字。改位置可调 .offset(y:)（负值向上）；改字号调 size: side * 0.32
                Text("\(count)")
                    .font(.system(size: side * 0.32, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: -side * 0.06)
            }
            .overlay(alignment: .bottomTrailing) {
                // 首字（initial）仅当 toggle 开启且非空时显示在右下角。改位置调 .offset(x:y:)（x 负左正右，y 负上正下）；改字号调 size: max(9, side * 0.2)
                if !initial.isEmpty {
                    Text(initial)
                        .font(.system(size: max(5, side * 0.15), weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(min(5, side * 0.08))
                        .offset(x: -18, y: -18)
                }
            }
            .frame(width: side, height: side)
            .clipped()
    }

    private func fontSizeFor(_ side: CGFloat) -> CGFloat {
        if side >= 70 { return 13 }
        if side >= 50 { return 11 }
        return 10
    }

    private func widgetButtonSize(count: Int) -> CGFloat {
        let totalW: CGFloat = 155
        let totalH: CGFloat = 155
        let spacing: CGFloat = count <= 2 ? 4 : 3
        let inset: CGFloat = 12
        if count == 1 {
            return min(100, totalW - inset * 2)
        }
        if count == 2 {
            return (totalW - inset * 2 - spacing) / 2
        }
        return (min(totalW, totalH) - inset * 2 - spacing) / 2
    }
}

@main
struct PuffWidgetBundle: WidgetBundle {
    var body: some Widget {
        PuffWidget()
    }
}

struct PuffWidget: Widget {
    let kind: String = "PauseWidget"

    var body: some WidgetConfiguration {
        let isChinese = widgetAppLanguageIsChinese()
        return StaticConfiguration(kind: kind, provider: PuffWidgetProvider()) { entry in
            PuffWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("AntiRepeat")
        .description(isChinese ? "今日行为记录，点击按键快速记录" : "Today's behaviors, tap to record")
        .supportedFamilies([.systemSmall])
    }
}
