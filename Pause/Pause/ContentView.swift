//
//  ContentView.swift
//  Pause
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            RecordView()
                .tabItem {
                    Label(L10n.tabRecordFun(appState.isChinese), systemImage: "hand.tap.fill")
                }
            CalendarView()
                .tabItem {
                    Label(L10n.tabCalendar(appState.isChinese), systemImage: "calendar")
                }
            StatisticsView()
                .tabItem {
                    Label(L10n.tabStatistics(appState.isChinese), systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .tint(.accentColor)
        .environmentObject(appState)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            appState.refresh()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
