//
//  CalendarView.swift
//  Puff
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var currentMonth: Date = Date()
    @State private var showPaywall = false
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                fullCalendar
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
            .navigationBarTitleDisplayMode(.large)
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
            .padding(.top, 24)
            
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
                                isToday: calendar.isDateInToday(date)
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
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(Color.primary)
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .frame(height: 56)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppState())
    }
}
