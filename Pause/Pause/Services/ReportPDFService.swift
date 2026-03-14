//
//  ReportPDFService.swift
//  Pause
//
//  将放屁报告导出为 PDF（文本摘要，不含图表）。
//

import UIKit

enum ReportPDFService {
    /// 根据当前周期与语言生成报告 PDF 的 Data
    static func generate(
        period: StatsPeriod,
        appState: AppState,
        isChinese: Bool
    ) -> Data? {
        let cal = Calendar.current
        let now = Date()
        let range = periodRange(period: period, calendar: cal, now: now)
        let total = appState.records(from: range.start, to: range.end).count
        let behaviorDist = appState.behaviorDistribution(from: range.start, to: range.end)
        let periodName = period.displayName(isChinese: isChinese)
        let title = isChinese ? "行为报告" : "Pause Report"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: isChinese ? "zh_CN" : "en_US")
        let fromStr = dateFormatter.string(from: range.start)
        let toStr = dateFormatter.string(from: range.end)
        let summary = L10n.summaryPhrase(isChinese, total)
        return renderPDF(
            title: title,
            periodName: periodName,
            dateRange: "\(fromStr) – \(toStr)",
            total: total,
            summary: summary,
            behaviorDistribution: behaviorDist,
            isChinese: isChinese
        )
    }
    
    private static func periodRange(period: StatsPeriod, calendar: Calendar, now: Date) -> (start: Date, end: Date) {
        switch period {
        case .week:
            let s = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            return (s, now)
        case .month:
            let s = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (s, now)
        case .threeMonths:
            let s = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return (s, now)
        case .sixMonths:
            let s = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return (s, now)
        case .nineMonths:
            let s = calendar.date(byAdding: .month, value: -9, to: now) ?? now
            return (s, now)
        case .year:
            let s = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (s, now)
        }
    }
    
    private static func renderPDF(
        title: String,
        periodName: String,
        dateRange: String,
        total: Int,
        summary: String,
        behaviorDistribution: [(name: String, count: Int)],
        isChinese: Bool
    ) -> Data? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let lineHeight: CGFloat = 24
        let titleFont = UIFont.boldSystemFont(ofSize: 22)
        let headFont = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        return renderer.pdfData { context in
            context.beginPage(withBounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), pageInfo: [:])
            let attrsTitle: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            let attrsHead: [NSAttributedString.Key: Any] = [.font: headFont, .foregroundColor: UIColor.darkGray]
            let attrsBody: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            
            var y = margin
            (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsTitle)
            y += lineHeight * 1.5
            (periodName as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsHead)
            y += lineHeight
            (dateRange as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsBody)
            y += lineHeight * 1.2
            
            let totalLabel = isChinese ? "总次数" : "Total"
            ("\(totalLabel): \(total)" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsHead)
            y += lineHeight
            (summary as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsBody)
            y += lineHeight * 1.5
            
            if !behaviorDistribution.isEmpty {
                let sectionTitle = isChinese ? "行为分布" : "Behavior distribution"
                (sectionTitle as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsHead)
                y += lineHeight
                for (name, count) in behaviorDistribution.prefix(12) {
                    ("  \(name): \(count)" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrsBody)
                    y += lineHeight * 0.9
                }
            }
        }
    }
}
