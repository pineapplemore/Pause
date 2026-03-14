//
//  L10n.swift
//  Puff
//
//  中英文文案（根据当前语言返回）
//

import Foundation

enum L10n {
    static func tabRecord(_ isChinese: Bool) -> String { isChinese ? "记录" : "Record" }
    static func tabCalendar(_ isChinese: Bool) -> String { isChinese ? "日历" : "Calendar" }
    static func tabStatistics(_ isChinese: Bool) -> String { isChinese ? "统计" : "Statistics" }
    
    static func recordOnce(_ isChinese: Bool) -> String { isChinese ? "记录一次" : "Record" }
    static func tagMultiSelect(_ isChinese: Bool) -> String { isChinese ? "标签（可多选）" : "Tags (multi-select)" }
    static func showTagDeleteButtons(_ isChinese: Bool) -> String { isChinese ? "显示删除按钮" : "Show delete buttons" }
    static func customTag(_ isChinese: Bool) -> String { isChinese ? "自定义" : "Custom" }
    static func addCustomTag(_ isChinese: Bool) -> String { isChinese ? "添加自定义标签" : "Add custom tag" }
    static func customTagPlaceholder(_ isChinese: Bool) -> String { isChinese ? "输入标签名" : "Tag name" }
    static func removeTagFromList(_ isChinese: Bool) -> String { isChinese ? "从标签列表中移除？历史记录仍会保留。" : "Remove from tag list? Past records keep it." }
    static func cancel(_ isChinese: Bool) -> String { isChinese ? "取消" : "Cancel" }
    static func confirm(_ isChinese: Bool) -> String { isChinese ? "确定" : "OK" }
    
    static func calendarTitle(_ isChinese: Bool) -> String { isChinese ? "日历" : "Calendar" }
    static func monthYearFormat(_ isChinese: Bool) -> String { isChinese ? "yyyy年M月" : "MMM yyyy" }
    static func viewDayDetail(_ isChinese: Bool) -> String { isChinese ? "查看当日详情" : "View day" }
    static func weekdays(_ isChinese: Bool) -> [String] {
        isChinese ? ["日", "一", "二", "三", "四", "五", "六"] : ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    static func statisticsTitle(_ isChinese: Bool) -> String { isChinese ? "统计" : "Statistics" }
    static func periodLabel(_ isChinese: Bool) -> String { isChinese ? "统计周期" : "Period" }
    static func periodSummary(_ isChinese: Bool) -> String { isChinese ? "本周期汇总" : "Summary" }
    static func totalCount(_ isChinese: Bool) -> String { isChinese ? "总次数" : "Total" }
    static func periodComparison(_ isChinese: Bool) -> String { isChinese ? "周期对比" : "Comparison" }
    static func hourlyDistribution(_ isChinese: Bool) -> String { isChinese ? "每日时段分布" : "Hourly distribution" }
    static func hourlyHint(_ isChinese: Bool) -> String { isChinese ? "可看出一天中哪个时段放屁最多，如午饭后等" : "Peak hours in a day (e.g. after lunch)" }
    /// 每日时段分布下方标注：最近一次记录的日期
    static func hourlyChartDateLabel(_ isChinese: Bool, _ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = isChinese ? "M月d日" : "MMM d"
        fmt.locale = Locale(identifier: isChinese ? "zh_Hans" : "en_US")
        let str = fmt.string(from: date)
        return isChinese ? "最近一次记录日：\(str)" : "Last record: \(str)"
    }
    static func last7RecordDaysTitle(_ isChinese: Bool) -> String { isChinese ? "最近 7 个有记录日对比" : "Last 7 days with records" }
    static func last7RecordDaysHint(_ isChinese: Bool) -> String { isChinese ? "按 0–23 点时段，7 天用不同颜色" : "By hour (0–23), 7 days in different colors" }
    
    static func dayDetailTitleFormat(_ isChinese: Bool) -> String { isChinese ? "M月d日" : "MMM d" }
    static func dayDetailTotal(_ isChinese: Bool) -> String { isChinese ? "共" : "" }
    static func dayDetailTimes(_ isChinese: Bool) -> String { isChinese ? "次" : " times" }
    static func dayDetailList(_ isChinese: Bool) -> String { isChinese ? "记录列表" : "Records" }
    static func dayDetailEmpty(_ isChinese: Bool) -> String { isChinese ? "当日暂无记录" : "No records" }
    static func dayDetailNoTag(_ isChinese: Bool) -> String { isChinese ? "未选标签" : "No tag" }
    static func delete(_ isChinese: Bool) -> String { isChinese ? "删除" : "Delete" }
    static func deleteRecordConfirm(_ isChinese: Bool) -> String { isChinese ? "确定删除这条记录？" : "Delete this record?" }
    
    static func retroactiveLog(_ isChinese: Bool) -> String { isChinese ? "补登" : "Log earlier" }
    static func retroactiveTitle(_ isChinese: Bool) -> String { isChinese ? "选择多久之前" : "How long ago?" }
    static func minutesAgo(_ isChinese: Bool, _ n: Int) -> String { isChinese ? "\(n)分钟前" : "\(n) min ago" }
    static func customMinutes(_ isChinese: Bool) -> String { isChinese ? "自定义" : "Custom" }
    static func customMinutesPlaceholder(_ isChinese: Bool) -> String { isChinese ? "输入分钟数" : "Minutes" }
    
    static func reportTitle(_ isChinese: Bool) -> String { isChinese ? "放屁报告" : "Puff Report" }
    static func tabRecordFun(_ isChinese: Bool) -> String { isChinese ? "今日战绩" : "Today" }
    static func tagDistribution(_ isChinese: Bool) -> String { isChinese ? "标签分布" : "Tag distribution" }
    /// 多选说明：各标签次数之和可能大于记录数，故不用饼图
    static func tagDistributionHint(_ isChinese: Bool) -> String { isChinese ? "下方为各类型屁的被选次数（可多选）" : "Count by puff type below (multi-select)" }
    static func showTagDistribution(_ isChinese: Bool) -> String { isChinese ? "显示标签分布" : "Show tag distribution" }
    static func peakHour(_ isChinese: Bool) -> String { isChinese ? "一天中的高光时刻" : "Peak puff hours" }
    static func consecutiveDays(_ isChinese: Bool) -> String { isChinese ? "连续记录" : "Streak" }
    static func daysSuffix(_ isChinese: Bool) -> String { isChinese ? "天" : " days" }
    static func vsLastWeek(_ isChinese: Bool) -> String { isChinese ? "与上周对比" : "vs last week" }
    static func weekdaysDistribution(_ isChinese: Bool) -> String { isChinese ? "星期分布" : "By weekday" }
    static func weekdayLabels(_ isChinese: Bool) -> [String] {
        isChinese ? ["日", "一", "二", "三", "四", "五", "六"] : ["S", "M", "T", "W", "T", "F", "S"]
    }
    static func peakHourText(_ isChinese: Bool, _ hour: Int) -> String {
        if isChinese { return "约 \(hour):00–\(hour + 1):00 最多" }
        return "Peak: \(hour):00–\(hour + 1):00"
    }
    static func summaryPhrase(_ isChinese: Bool, _ count: Int) -> String {
        if isChinese {
            if count == 0 { return "本周还没开张。" }
            if count < 5 { return "本周期共 \(count) 次，稳中有进。" }
            if count < 15 { return "本周期共 \(count) 次，比上周更从容。" }
            return "本周期共 \(count) 次，屁力全开。"
        } else {
            if count == 0 { return "No puffs this period yet." }
            if count < 5 { return "\(count) total. Steady." }
            if count < 15 { return "\(count) total. Keep it real." }
            return "\(count) total. Full power."
        }
    }
    static func noRecordsToday(_ isChinese: Bool) -> String { isChinese ? "今天还没开张" : "No puffs yet today" }
    
    /// 小彩蛋：累计达到里程碑时的祝贺文案
    static func milestoneTitle(_ isChinese: Bool, _ count: Int) -> String {
        if isChinese {
            switch count {
            case 10: return "🎉 破十啦"
            case 50: return "🎉 半百达成"
            case 100: return "🎉 百屁大关"
            case 500: return "🎉 五百屁力"
            case 1000: return "🎉 千屁传说"
            default: return "🎉 里程碑"
            }
        } else {
            switch count {
            case 10: return "🎉 10 puffs!"
            case 50: return "🎉 50 puffs!"
            case 100: return "🎉 100 puffs!"
            case 500: return "🎉 500 puffs!"
            case 1000: return "🎉 1000 puffs!"
            default: return "🎉 Milestone!"
            }
        }
    }
    // 订阅与 PDF
    static func subscribe(_ isChinese: Bool) -> String { isChinese ? "订阅" : "Subscribe" }
    static func subscriptionTitle(_ isChinese: Bool) -> String { isChinese ? "解锁完整功能" : "Unlock full access" }
    static func subscriptionBenefits(_ isChinese: Bool) -> [String] {
        isChinese ? ["导出放屁报告 PDF", "多周期数据对比", "持续更新与支持"] : ["Export report as PDF", "Multi-period comparison", "Ongoing updates"]
    }
    static func trialNotice(_ isChinese: Bool) -> String { isChinese ? "3 天免费试用，随后按年订阅" : "3-day free trial, then annual" }
    static func annualPrice(_ isChinese: Bool, _ price: String) -> String { isChinese ? "¥\(price)/年" : "$\(price)/year" }
    static func startTrial(_ isChinese: Bool) -> String { isChinese ? "开始 3 天免费试用" : "Start 3-day free trial" }
    static func restorePurchases(_ isChinese: Bool) -> String { isChinese ? "恢复购买" : "Restore" }
    static func productsLoadFailed(_ isChinese: Bool) -> String { isChinese ? "无法加载产品，请检查网络后重试" : "Unable to load products. Check connection and retry." }
    static func retry(_ isChinese: Bool) -> String { isChinese ? "重试" : "Retry" }
    static func requestTimeout(_ isChinese: Bool) -> String { isChinese ? "请求超时，请重试" : "Request timed out. Please retry." }
    static func subscriptionName(_ isChinese: Bool) -> String { isChinese ? "PuffDiary 年度订阅" : "PuffDiary Annual" }
    static func subscriptionLength(_ isChinese: Bool) -> String { isChinese ? "订阅周期：1 年" : "Subscription period: 1 year" }
    static func termsOfUse(_ isChinese: Bool) -> String { isChinese ? "使用条款（EULA）" : "Terms of Use (EULA)" }
    static func privacyPolicy(_ isChinese: Bool) -> String { isChinese ? "隐私政策" : "Privacy Policy" }
    static func thenPerYear(_ isChinese: Bool) -> String { isChinese ? "随后按年续订" : "then renews annually" }
    static func exportPDF(_ isChinese: Bool) -> String { isChinese ? "导出 PDF" : "Export PDF" }
    static func pdfExportSuccess(_ isChinese: Bool) -> String { isChinese ? "报告已导出" : "Report exported" }
    static func pdfExportSubscriberOnly(_ isChinese: Bool) -> String { isChinese ? "导出 PDF 需订阅" : "Subscribe to export PDF" }
    static func subscriptionRequiredForCalendar(_ isChinese: Bool) -> String { isChinese ? "订阅后可查看历史日历" : "Subscribe to view calendar history" }
    static func subscriptionRequiredForStats(_ isChinese: Bool) -> String { isChinese ? "需要订阅以查看完整统计" : "Subscribe to view full statistics" }
    static func viewTodayOnly(_ isChinese: Bool) -> String { isChinese ? "仅可查看今日记录" : "View today only" }
    
    // 设定 / 小组件常用标签
    static func tabSettings(_ isChinese: Bool) -> String { isChinese ? "设定" : "Settings" }
    static func widgetFavoriteTagsTitle(_ isChinese: Bool) -> String { isChinese ? "小组件常用标签" : "Widget quick tags" }
    static func widgetFavoriteTagsSubtitle(_ isChinese: Bool) -> String { isChinese ? "在小组件上显示最多 3 个标签，点击即可带标签记录" : "Show up to 3 tags on widget; tap to record with that tag" }
    static func widgetSelected(_ isChinese: Bool) -> String { isChinese ? "已选（点击移除）" : "Selected (tap to remove)" }
    static func widgetAvailable(_ isChinese: Bool) -> String { isChinese ? "可选（点击加入）" : "Available (tap to add)" }
    static func remove(_ isChinese: Bool) -> String { isChinese ? "移除" : "Remove" }
    /// 小组件标签仅适用于 iPhone 17 等机型
    static func widgetTagDeviceHint(_ isChinese: Bool) -> String { isChinese ? "小组件标签点击记录仅适用于 iPhone 17 等支持交互小组件的机型。" : "Widget quick tags work on iPhone 17 and other devices with interactive widgets." }
    
    static func milestoneMessage(_ isChinese: Bool, _ count: Int) -> String {
        if isChinese {
            switch count {
            case 10: return "累计记录已达 10 次，屁路漫长，继续加油。"
            case 50: return "已记录 50 次，你已是半个屁学专家。"
            case 100: return "突破 100 次！放屁报告将为你铭记。"
            case 500: return "五百次达成，屁力全开，无人能挡。"
            case 1000: return "千屁成就解锁，传说中的屁王就是你了。"
            default: return "恭喜达成新里程碑！"
            }
        } else {
            switch count {
            case 10: return "You've logged 10 puffs. The journey continues!"
            case 50: return "50 puffs! You're half an expert."
            case 100: return "100 puffs! Your report will remember."
            case 500: return "500 reached. Full power!"
            case 1000: return "1000 puffs. You're a legend."
            default: return "New milestone unlocked!"
            }
        }
    }
}
