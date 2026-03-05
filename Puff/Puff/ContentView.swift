//
//  ContentView.swift
//  Puff
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            RecordView()
                .tabItem {
                    Label(L10n.tabRecordFun(appState.isChinese), systemImage: "wind")
                }
            CalendarView()
                .tabItem {
                    Label(L10n.tabCalendar(appState.isChinese), systemImage: "calendar")
                }
            StatisticsView()
                .tabItem {
                    Label(L10n.tabStatistics(appState.isChinese), systemImage: "chart.line.uptrend.xyaxis")
                }
            SettingsView()
                .tabItem {
                    Label(L10n.tabSettings(appState.isChinese), systemImage: "gearshape")
                }
        }
        .tint(.accentColor)
        .environmentObject(appState)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
