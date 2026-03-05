//
//  StatisticsView.swift
//  Puff
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
    @AppStorage("Puff.showTagDistribution") private var showTagDistribution = true
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                    // 不受周期影响的固定块：放上面
                    WeekOverWeekCard(appState: appState)
                    HourlyChartCard(appState: appState, period: selectedPeriod, fixedDays: 7)
                    WeekdayDistributionCard(appState: appState, period: selectedPeriod, fixedDays: 30)
                    
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
                    
                    TagDistributionCard(appState: appState, period: selectedPeriod, isExpanded: $showTagDistribution)
                    
                    PeriodComparisonCard(appState: appState, period: selectedPeriod)
                }
                .padding()
                }
                .background(Color(.systemGroupedBackground))
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
        let fileName = "PuffReport_\(dateStr).pdf"
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

// 自定义折线图（兼容 iOS 15）；fixedDays 非空时忽略 period，用最近 fixedDays 天
struct HourlyChartCard: View {
    @ObservedObject var appState: AppState
    let period: StatsPeriod
    var fixedDays: Int? = nil
    
    private var datesInPeriod: [Date] {
        let cal = Calendar.current
        let now = Date()
        if let days = fixedDays, days > 0 {
            var d = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: now)) ?? now
            var list: [Date] = []
            for _ in 0..<days {
                list.append(d)
                d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
            return list
        }
        var start: Date
        switch period {
        case .week: start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        case .month: start = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths: start = cal.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths: start = cal.date(byAdding: .month, value: -6, to: now) ?? now
        case .nineMonths: start = cal.date(byAdding: .month, value: -9, to: now) ?? now
        case .year: start = cal.date(byAdding: .year, value: -1, to: now) ?? now
        }
        var d = cal.startOfDay(for: start)
        var list: [Date] = []
        while d <= now {
            list.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return list
    }
    
    private var hourlyData: [(hour: Int, count: Int)] {
        let counts = appState.hourlyCounts(for: datesInPeriod)
        return counts.enumerated().map { ($0.offset, $0.element) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.hourlyDistribution(appState.isChinese))
                .font(.headline)
            Text(L10n.hourlyHint(appState.isChinese))
                .font(.caption)
                .foregroundStyle(.secondary)
            SimpleLineChartView(data: hourlyData.map { $0.count }, labels: hourlyData.map { "\($0.hour)" })
                .frame(height: 200)
            if let peak = appState.peakHour(from: datesInPeriod) {
                Text(L10n.peakHourText(appState.isChinese, peak))
                    .font(.caption)
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TagDistributionCard: View {
    @ObservedObject var appState: AppState
    let period: StatsPeriod
    @Binding var isExpanded: Bool
    
    private var periodRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .week: return (cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now, now)
        case .month: return (cal.date(byAdding: .month, value: -1, to: now) ?? now, now)
        case .threeMonths: return (cal.date(byAdding: .month, value: -3, to: now) ?? now, now)
        case .sixMonths: return (cal.date(byAdding: .month, value: -6, to: now) ?? now, now)
        case .nineMonths: return (cal.date(byAdding: .month, value: -9, to: now) ?? now, now)
        case .year: return (cal.date(byAdding: .year, value: -1, to: now) ?? now, now)
        }
    }
    
    private var distribution: [(String, Int)] {
        appState.tagDistribution(from: periodRange.start, to: periodRange.end)
    }
    
    private func tagDisplayName(_ tagId: String) -> String {
        if let t = PuffType(rawValue: tagId) { return t.displayName(isChinese: appState.isChinese) }
        if tagId.hasPrefix("custom:") { return String(tagId.dropFirst(7)) }
        return tagId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tagDistribution(appState.isChinese))
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $isExpanded)
                    .labelsHidden()
            }
            if isExpanded {
                Text(L10n.tagDistributionHint(appState.isChinese))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if distribution.isEmpty {
                    Text(appState.isChinese ? "本周期暂无标签数据" : "No tag data this period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(distribution.prefix(8)), id: \.0) { tagId, count in
                        HStack {
                            Text(tagDisplayName(tagId))
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color.accentColor)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

struct WeekdayDistributionCard: View {
    @ObservedObject var appState: AppState
    let period: StatsPeriod
    var fixedDays: Int? = nil
    
    private var datesInPeriod: [Date] {
        let cal = Calendar.current
        let now = Date()
        if let days = fixedDays, days > 0 {
            var d = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: now)) ?? now
            var list: [Date] = []
            for _ in 0..<days {
                list.append(d)
                d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
            return list
        }
        var start: Date
        switch period {
        case .week: start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        case .month: start = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths: start = cal.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths: start = cal.date(byAdding: .month, value: -6, to: now) ?? now
        case .nineMonths: start = cal.date(byAdding: .month, value: -9, to: now) ?? now
        case .year: start = cal.date(byAdding: .year, value: -1, to: now) ?? now
        }
        var d = cal.startOfDay(for: start)
        var list: [Date] = []
        while d <= now {
            list.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return list
    }
    
    private var weekdayCounts: [Int] {
        let cal = Calendar.current
        var counts = Array(repeating: 0, count: 7)
        for date in datesInPeriod {
            for record in appState.records(on: date) {
                let w = cal.component(.weekday, from: record.timestamp) - 1
                counts[w] += 1
            }
        }
        return counts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.weekdaysDistribution(appState.isChinese))
                .font(.headline)
            let labels = L10n.weekdayLabels(appState.isChinese)
            let data = weekdayCounts
            let maxVal = max(data.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(height: max(4, CGFloat(data[i]) / CGFloat(maxVal) * 80))
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
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

struct SimpleBarChartView: View {
    let data: [(label: String, value: Int)]
    
    var body: some View {
        let maxVal = data.map(\.value).max() ?? 1
        GeometryReader { geo in
            let h = geo.size.height
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
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
