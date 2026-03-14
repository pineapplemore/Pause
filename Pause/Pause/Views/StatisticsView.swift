//
//  StatisticsView.swift
//  Pause
//
//  统计：周期对比 + 每日时段折线图（纯 SwiftUI，兼容 iOS 15）
//

import SwiftUI
import UIKit

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "周"
    case month = "月"
    case threeMonths = "3个月"
    case sixMonths = "6个月"
    case nineMonths = "9个月"
    case year = "1年"
    var id: String { rawValue }
    func displayName(isChinese: Bool) -> String {
        if isChinese { return rawValue }
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .nineMonths: return "9M"
        case .year: return "1Y"
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var showPaywall = false
    @State private var shareablePDFItem: ShareablePDFItem?
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                    // 不受周期影响的固定块：放上面
                    WeekOverWeekCard(appState: appState)
                    HourlyChartCard(appState: appState, period: selectedPeriod, fixedDays: 7)
                    Last7RecordDaysChartCard(appState: appState)
                    
                    // 统计周期选择（仅影响下面的本周期汇总、周期对比、标签分布）
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.periodLabel(appState.isChinese))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(StatsPeriod.allCases) { p in
                                    Button {
                                        selectedPeriod = p
                                    } label: {
                                        Text(p.displayName(isChinese: appState.isChinese))
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(selectedPeriod == p ? .white : .primary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(selectedPeriod == p ? Color.accentColor : Color(.tertiarySystemFill))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    PeriodSummaryCard(period: selectedPeriod, appState: appState)
                    
                    BehaviorTrendCard(appState: appState, period: selectedPeriod)
                    
                    PeriodComparisonCard(appState: appState, period: selectedPeriod)
                }
                .padding()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                if !subscriptionManager.hasAccess {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text(L10n.subscriptionRequiredForStats(appState.isChinese))
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            showPaywall = true
                        } label: {
                            Text(L10n.subscribe(appState.isChinese))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(L10n.reportTitle(appState.isChinese))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text(L10n.subscribe(appState.isChinese))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(Color.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportPDFTapped()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text(L10n.exportPDF(appState.isChinese))
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(appState)
            }
            .sheet(item: $shareablePDFItem, onDismiss: { shareablePDFItem = nil }) { item in
                ShareSheet(activityItems: [item.url as Any])
            }
            .alert(L10n.exportPDF(appState.isChinese), isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button(L10n.confirm(appState.isChinese)) { exportError = nil }
            } message: {
                if let msg = exportError { Text(msg) }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func exportPDFTapped() {
        if !subscriptionManager.hasAccess {
            showPaywall = true
            return
        }
        guard let data = ReportPDFService.generate(period: selectedPeriod, appState: appState, isChinese: appState.isChinese) else {
            exportError = "Export failed"
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        let fileName = "AntiRepeatReport_\(dateStr).pdf"
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: temp)
            shareablePDFItem = ShareablePDFItem(url: temp)
        } catch {
            exportError = error.localizedDescription
        }
    }
}

struct ShareablePDFItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PeriodSummaryCard: View {
    let period: StatsPeriod
    @ObservedObject var appState: AppState
    
    private var periodRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .week:
            let s = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
            return (s, now)
        case .month:
            let s = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return (s, now)
        case .threeMonths:
            let s = cal.date(byAdding: .month, value: -3, to: now) ?? now
            return (s, now)
        case .sixMonths:
            let s = cal.date(byAdding: .month, value: -6, to: now) ?? now
            return (s, now)
        case .nineMonths:
            let s = cal.date(byAdding: .month, value: -9, to: now) ?? now
            return (s, now)
        case .year:
            let s = cal.date(byAdding: .year, value: -1, to: now) ?? now
            return (s, now)
        }
    }
    
    private var totalCount: Int {
        appState.records(from: periodRange.start, to: periodRange.end).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.periodSummary(appState.isChinese))
                .font(.headline)
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalCount)")
                        .font(.title.weight(.semibold))
                        .foregroundColor(Color.accentColor)
                    Text(L10n.totalCount(appState.isChinese))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(L10n.summaryPhrase(appState.isChinese, totalCount))
                .font(.caption)
                .foregroundStyle(.secondary)
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// 每日时段分布：可选行为 + 选择日期，选「全部」时为所有行为合计的 0–23 点
struct HourlyChartCard: View {
    @ObservedObject var appState: AppState
    let period: StatsPeriod
    var fixedDays: Int? = nil
    @State private var selectedBehaviorIdKey: String = ""
    /// nil = 使用最近一次记录日；有值 = 用户选择的日期
    @State private var selectedChartDate: Date?

    private var dateOfMostRecentRecord: Date? {
        guard let first = appState.records.first else { return nil }
        return Calendar.current.startOfDay(for: first.timestamp)
    }

    /// 用于图表的单日：优先用户选择日，否则最近记录日
    private var chartDate: Date? {
        selectedChartDate ?? dateOfMostRecentRecord
    }

    private var singleDayForChart: [Date] {
        guard let d = chartDate else { return [] }
        return [d]
    }

    private var selectedBehaviorId: String? { selectedBehaviorIdKey.isEmpty ? nil : selectedBehaviorIdKey }

    /// 单选一个行为：一条折线
    private var hourlyData: [(hour: Int, count: Int)] {
        let counts = appState.hourlyCounts(for: singleDayForChart, behaviorId: selectedBehaviorId)
        return counts.enumerated().map { ($0.offset, $0.element) }
    }

    /// 选「全部」：每个行为一条折线，一色一线
    private var hourlySeriesAllBehaviors: [(name: String, color: Color, values: [Int])] {
        let options = appState.allAvailableTagOptions()
        return options.enumerated().map { idx, opt in
            let counts = appState.hourlyCounts(for: singleDayForChart, behaviorId: opt.id)
            return (opt.name, Behavior.morandiColor(at: idx), counts)
        }
    }

    private var behaviorOptions: [(id: String, name: String)] {
        [("", L10n.allBehaviors(appState.isChinese))] + appState.allAvailableTagOptions().map { ($0.id, $0.name) }
    }

    /// 日期选择范围：有记录则从最早记录日到今天，否则过去一年到今天
    private var datePickerRange: ClosedRange<Date> {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        if let last = appState.records.last {
            let start = cal.startOfDay(for: last.timestamp)
            return start ... now
        }
        let start = cal.date(byAdding: .year, value: -1, to: now) ?? now
        return start ... now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.hourlyDistribution(appState.isChinese))
                .font(.headline)
            Picker("", selection: $selectedBehaviorIdKey) {
                ForEach(behaviorOptions, id: \.id) { opt in
                    Text(opt.name).tag(opt.id)
                }
            }
            .pickerStyle(.menu)
            HStack(alignment: .center, spacing: 8) {
                Text(L10n.selectDateForHourly(appState.isChinese))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker("", selection: Binding(
                    get: { chartDate ?? Date() },
                    set: { selectedChartDate = Calendar.current.startOfDay(for: $0) }
                ), in: datePickerRange, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
            }
            if let date = chartDate {
                Text(L10n.hourlyChartDateLabel(appState.isChinese, date))
                    .font(.caption)
                    .foregroundColor(Color.accentColor)
            }
            Text(L10n.hourlyHint(appState.isChinese))
                .font(.caption)
                .foregroundStyle(.secondary)
            if singleDayForChart.isEmpty {
                Text(appState.isChinese ? "暂无记录" : "No records")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else if selectedBehaviorIdKey.isEmpty {
                let series = hourlySeriesAllBehaviors
                let xLabels = (0..<24).map { "\($0)" }
                if series.isEmpty {
                    Text(appState.isChinese ? "暂无记录" : "No records")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    SimpleMultiLineChartView(xLabels: xLabels, series: series)
                        .frame(height: 200)
                }
            } else {
                SimpleLineChartView(data: hourlyData.map { $0.count }, labels: hourlyData.map { "\($0.hour)" })
                    .frame(height: 200)
                if let peak = appState.peakHour(from: singleDayForChart, behaviorId: selectedBehaviorId) {
                    Text(L10n.peakHourText(appState.isChinese, peak))
                        .font(.caption)
                        .foregroundColor(Color.accentColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// 莫兰迪 7 色（用于最近 7 个有记录日折线）
private let kMorandiChartColors: [Color] = [
    Color(red: 0.55, green: 0.58, blue: 0.48),
    Color(red: 0.58, green: 0.52, blue: 0.62),
    Color(red: 0.45, green: 0.55, blue: 0.62),
    Color(red: 0.42, green: 0.58, blue: 0.58),
    Color(red: 0.65, green: 0.52, blue: 0.48),
    Color(red: 0.48, green: 0.58, blue: 0.60),
    Color(red: 0.62, green: 0.48, blue: 0.40)
]

/// 最近 7 个「有记录」的日期（可按行为筛选），每天一条折线
struct Last7RecordDaysChartCard: View {
    @ObservedObject var appState: AppState
    @State private var selectedBehaviorIdKey: String = ""

    private static func dateLabel(for date: Date, isChinese: Bool) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = isChinese ? "M/d" : "MMM d"
        fmt.locale = Locale(identifier: isChinese ? "zh_Hans" : "en_US")
        return fmt.string(from: date)
    }

    private var selectedBehaviorId: String? { selectedBehaviorIdKey.isEmpty ? nil : selectedBehaviorIdKey }

    private var behaviorOptions: [(id: String, name: String)] {
        [("", L10n.allBehaviors(appState.isChinese))] + appState.allAvailableTagOptions().map { ($0.id, $0.name) }
    }

    private func last7LegendView(days: [(date: Date, counts: [Int])]) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(kMorandiChartColors[i % kMorandiChartColors.count])
                        .frame(width: 10, height: 10)
                    Text(Last7RecordDaysChartCard.dateLabel(for: item.date, isChinese: appState.isChinese))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// 从今天起往前找，有记录的日期（按所选行为筛选），最多 7 天
    private var last7RecordDays: [(date: Date, counts: [Int])] {
        let cal = Calendar.current
        var d = cal.startOfDay(for: Date())
        var result: [(Date, [Int])] = []
        for _ in 0..<365 {
            let counts = appState.hourlyCounts(for: [d], behaviorId: selectedBehaviorId)
            let cnt = counts.reduce(0, +)
            if cnt > 0 {
                result.append((d, counts))
                if result.count >= 7 { break }
            }
            guard let next = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = next
        }
        return result
    }

    private var globalMax: Int {
        last7RecordDays.flatMap { $0.counts }.max() ?? 1
    }

    var body: some View {
        let days = last7RecordDays
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.last7RecordDaysTitle(appState.isChinese))
                .font(.headline)
            Picker("", selection: $selectedBehaviorIdKey) {
                ForEach(behaviorOptions, id: \.id) { opt in
                    Text(opt.name).tag(opt.id)
                }
            }
            .pickerStyle(.menu)
            Text(L10n.last7RecordDaysHint(appState.isChinese))
                .font(.caption)
                .foregroundStyle(.secondary)
            if days.isEmpty {
                Text(appState.isChinese ? "暂无有记录日" : "No days with records")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                MultiLineChartView(days: days, maxValue: max(globalMax, 1), colors: kMorandiChartColors)
                    .frame(height: 200)
                last7LegendView(days: days)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// 多条折线（每条为 24 小时数据）
struct MultiLineChartView: View {
    let days: [(date: Date, counts: [Int])]
    let maxValue: Int
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stepX = (w - 24) / 24
            let maxVal = CGFloat(maxValue)
            ZStack(alignment: .bottom) {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                    let pts = day.counts.enumerated().map { i, v -> CGPoint in
                        let x = 12 + CGFloat(i) * stepX + stepX / 2
                        let y = h - 20 - (maxVal > 0 ? (CGFloat(v) / maxVal) * (h - 32) : 0)
                        return CGPoint(x: x, y: y)
                    }
                    if pts.count >= 2 {
                        Path { p in
                            p.move(to: pts[0])
                            for pt in pts.dropFirst() { p.addLine(to: pt) }
                        }
                        .stroke(colors[idx % colors.count], lineWidth: 2)
                    }
                }
            }
        }
    }
}

struct WeekOverWeekCard: View {
    @ObservedObject var appState: AppState
    
    private var thisWeekCount: Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        return appState.records(from: start, to: now).count
    }
    
    private var lastWeekCount: Int {
        let cal = Calendar.current
        let now = Date()
        let endOfLast = cal.date(byAdding: .day, value: -7, to: now) ?? now
        let startOfLast = cal.date(byAdding: .day, value: -13, to: now) ?? now
        return appState.records(from: startOfLast, to: endOfLast).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.vsLastWeek(appState.isChinese))
                .font(.headline)
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isChinese ? "本周" : "This week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(thisWeekCount)")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isChinese ? "上周" : "Last week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(lastWeekCount)")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(Color("SecondaryColor"))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SimpleLineChartView: View {
    let data: [Int]
    let labels: [String]
    private let maxValue: CGFloat
    
    init(data: [Int], labels: [String]) {
        self.data = data
        self.labels = labels
        self.maxValue = CGFloat(max(data.max() ?? 1, 1))
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stepX = data.isEmpty ? 0 : (w - 24) / CGFloat(data.count)
            let points: [(CGFloat, CGFloat)] = data.enumerated().map { i, v in
                let x = 12 + CGFloat(i) * stepX + stepX / 2
                let y = h - 20 - (CGFloat(v) / maxValue) * (h - 32)
                return (x, y)
            }
            ZStack(alignment: .bottom) {
                // 区域填充
                if !points.isEmpty {
                    Path { p in
                        p.move(to: CGPoint(x: points[0].0, y: h - 20))
                        for pt in points { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                        p.addLine(to: CGPoint(x: points.last!.0, y: h - 20))
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                // 折线
                if points.count >= 2 {
                    Path { p in
                        p.move(to: CGPoint(x: points[0].0, y: points[0].1))
                        for pt in points.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                    }
                    .stroke(Color.accentColor, lineWidth: 2)
                }
            }
        }
    }
}

/// 多系列折线（1～4 条，统计页各行为趋势用）
struct SimpleMultiLineChartView: View {
    let xLabels: [String]
    /// 每条线：(名称, 颜色, 每日数值)
    let series: [(name: String, color: Color, values: [Int])]
    
    private var maxValue: CGFloat {
        let m = series.flatMap(\.values).max() ?? 1
        return CGFloat(max(m, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height - 16
                let n = max(xLabels.count, 1)
                let stepX = (w - 24) / CGFloat(n)
                ZStack(alignment: .bottom) {
                    ForEach(Array(series.enumerated()), id: \.offset) { _, s in
                        if s.values.count >= 2, stepX > 0 {
                            Path { p in
                                for (i, v) in s.values.enumerated() {
                                    let x = 12 + CGFloat(i) * stepX + stepX / 2
                                    let y = h - 12 - (CGFloat(v) / maxValue) * (h - 24)
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(s.color, lineWidth: 2)
                        }
                    }
                }
                .frame(height: h)
            }
            .frame(height: 160)
            HStack(spacing: 12) {
                ForEach(Array(series.enumerated()), id: \.offset) { _, s in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(s.color)
                            .frame(width: 10, height: 10)
                        Text(s.name)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

private func behaviorTrendColors() -> [Color] {
    (0..<4).map { Behavior.morandiColor(at: $0) }
}

struct BehaviorTrendCard: View {
    @ObservedObject var appState: AppState
    let period: StatsPeriod
    
    private var periodRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .week:
            let s = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
            return (s, now)
        case .month:
            let s = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return (s, now)
        case .threeMonths:
            let s = cal.date(byAdding: .month, value: -3, to: now) ?? now
            return (s, now)
        case .sixMonths:
            let s = cal.date(byAdding: .month, value: -6, to: now) ?? now
            return (s, now)
        case .nineMonths:
            let s = cal.date(byAdding: .month, value: -9, to: now) ?? now
            return (s, now)
        case .year:
            let s = cal.date(byAdding: .year, value: -1, to: now) ?? now
            return (s, now)
        }
    }
    
    private var dayCount: Int {
        let cal = Calendar.current
        let (start, end) = periodRange
        return max(1, cal.dateComponents([.day], from: start, to: end).day ?? 7)
    }
    
    private var xLabels: [String] {
        let cal = Calendar.current
        let (start, end) = periodRange
        let fmt = DateFormatter()
        fmt.dateFormat = appState.isChinese ? "M/d" : "MMM d"
        fmt.locale = Locale(identifier: appState.isChinese ? "zh_Hans" : "en_US")
        var d = cal.startOfDay(for: start)
        var labels: [String] = []
        while d <= end {
            labels.append(fmt.string(from: d))
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return labels
    }
    
    /// 当前 1～4 个行为，每个行为一条线的每日数据
    private var chartSeries: [(name: String, color: Color, values: [Int])] {
        let (start, end) = periodRange
        let daily = appState.behaviorCountsPerDay(from: start, to: end)
        let ids = Array(Behavior.ids.prefix(appState.behaviorNames().count))
        let names = appState.behaviorNames()
        let colors = behaviorTrendColors()
        return ids.enumerated().map { idx, id in
            let name = idx < names.count ? names[idx] : id
            let values = daily.map { $0.counts[id] ?? 0 }
            return (name, colors[idx % colors.count], values)
        }
    }
    
    var body: some View {
        let series = chartSeries
        Group {
            if !series.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.behaviorTrendTitle(appState.isChinese))
                        .font(.headline)
                    SimpleMultiLineChartView(xLabels: xLabels, series: series)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

struct SimpleBarChartView: View {
    let data: [(label: String, value: Int)]
    
    var body: some View {
        let maxVal = max(data.map(\.value).max() ?? 1, 1)
        GeometryReader { geo in
            let h = geo.size.height
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(height: max(4, CGFloat(item.value) / CGFloat(maxVal) * (h - 28)))
                        Text(item.label)
                            .font(.system(size: 9))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct PeriodComparisonCard: View {
    @ObservedObject var appState: AppState
    let period: StatsPeriod
    
    private var comparisonData: [(label: String, value: Int)] {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .week:
            var result: [(String, Int)] = []
            let fmt = DateFormatter()
            fmt.dateFormat = "M/d"
            fmt.locale = Locale(identifier: "zh_Hans")
            for i in (0..<7).reversed() {
                guard let d = cal.date(byAdding: .day, value: -i, to: cal.startOfDay(for: now)) else { continue }
                result.append((fmt.string(from: d), appState.count(on: d)))
            }
            return result
        case .month, .threeMonths, .sixMonths, .nineMonths, .year:
            let monthsBack: Int
            switch period {
            case .month: monthsBack = 1
            case .threeMonths: monthsBack = 3
            case .sixMonths: monthsBack = 6
            case .nineMonths: monthsBack = 9
            case .year: monthsBack = 12
            default: monthsBack = 1
            }
            let fmt = DateFormatter()
            fmt.dateFormat = "M月"
            fmt.locale = Locale(identifier: "zh_Hans")
            var result: [(String, Int)] = []
            for i in (0..<monthsBack).reversed() {
                guard let d = cal.date(byAdding: .month, value: -i, to: now) else { continue }
                let start = cal.date(from: cal.dateComponents([.year, .month], from: d)) ?? d
                let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
                let count = appState.records(from: start, to: end).count
                result.append((fmt.string(from: d), count))
            }
            return result
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.periodComparison(appState.isChinese))
                .font(.headline)
            SimpleBarChartView(data: comparisonData)
                .frame(height: 180)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(AppState())
    }
}
