//
//  CalendarView.swift
//  Pause
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var currentMonth: Date = Date()
    @State private var showPaywall = false
    @State private var calendarPageReady = false
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                fullCalendar
                    .delayedPageLoading(
                        isOverlayEnabled: subscriptionManager.hasAccess,
                        message: L10n.pageLoading(appState.isChinese),
                        contentReady: $calendarPageReady
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
                if !subscriptionManager.hasAccess {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text(L10n.subscriptionRequiredForCalendar(appState.isChinese))
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
            .navigationTitle(L10n.calendarTitle(appState.isChinese))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var fullCalendar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { moveMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text(monthYearString(from: currentMonth))
                    .font(.title3.weight(.semibold))
                Spacer()
                Button { moveMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 4)

            HStack(spacing: 0) {
                ForEach(L10n.weekdays(appState.isChinese), id: \.self) { w in
                    Text(w)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        NavigationLink(destination: DayDetailView(date: date)) {
                            DayCell(
                                date: date,
                                count: appState.count(on: date),
                                isToday: calendar.isDateInToday(date),
                                enabledBehaviorIds: Array(Behavior.ids.prefix(appState.behaviorNames().count)),
                                appState: appState
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 56)
                    }
                }
            }
            .padding(.horizontal)

            Color.clear
                .frame(height: 1)
                .onAppear { calendarPageReady = true }
            
            Spacer(minLength: 0)
        }
    }
    
    private func moveMonth(_ delta: Int) {
        if let new = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = new
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.monthYearFormat(appState.isChinese)
        formatter.locale = Locale(identifier: appState.isChinese ? "zh_Hans" : "en_US")
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: first) - 1
        var result: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: first) {
                result.append(d)
            }
        }
        return result
    }
}

struct DayCell: View {
    let date: Date
    let count: Int
    let isToday: Bool
    var enabledBehaviorIds: [String] = []
    @ObservedObject var appState: AppState

    /// 当日各行为 id 的记录次数
    private var countPerBehavior: [String: Int] {
        let list = appState.records(on: date)
        var dict: [String: Int] = [:]
        for rec in list {
            for id in rec.typeIds where Behavior.ids.contains(id) {
                dict[id, default: 0] += 1
            }
        }
        return dict
    }

    /// 与主页行为按键一致的莫兰迪色
    private static func dotColor(for behaviorId: String) -> Color {
        guard let idx = Behavior.ids.firstIndex(of: behaviorId) else { return .gray }
        return Behavior.morandiColor(at: idx)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .bold : .regular, design: .rounded))
                .foregroundColor(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(count > 0 ? "\(count)" : " ")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(count > 0 ? Color.accentColor : Color.clear)
                .lineLimit(1)
                .frame(minHeight: 10)
            if !enabledBehaviorIds.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(enabledBehaviorIds, id: \.self) { id in
                        let n = countPerBehavior[id] ?? 0
                        HStack(spacing: 4) {
                            Circle()
                                .fill(n > 0 ? DayCell.dotColor(for: id) : Color(.tertiarySystemFill))
                                .frame(width: 5, height: 5)
                            if n > 0 {
                                Text("\(n)")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(DayCell.dotColor(for: id))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .frame(minHeight: 56)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppState())
    }
}
