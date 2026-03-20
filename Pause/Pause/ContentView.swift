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
        .onAppear {
            _ = SubscriptionManager.shared
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - 延迟加载（放在本文件避免远程构建漏加 Target 时找不到 .delayedPageLoading）
/// Tab 首屏较重时：约 0.35s 后仍无「就绪」信号则显示转圈。
struct DelayedPageLoadingModifier: ViewModifier {
    var isOverlayEnabled: Bool
    var message: String
    @Binding var contentReady: Bool

    @State private var showDelayedLoading = false
    @State private var appearToken = UUID()

    func body(content: Content) -> some View {
        ZStack {
            content
            if showDelayedLoading && isOverlayEnabled {
                ZStack {
                    Color(.systemBackground).opacity(0.75)
                        .ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .scaleEffect(1.15)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
        }
        .onAppear {
            contentReady = false
            showDelayedLoading = false
            let t = UUID()
            appearToken = t
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard appearToken == t else { return }
                if !contentReady { showDelayedLoading = true }
            }
        }
        .onDisappear {
            appearToken = UUID()
            showDelayedLoading = false
            contentReady = false
        }
        .onChange(of: contentReady) { ready in
            if ready { showDelayedLoading = false }
        }
    }
}

extension View {
    func delayedPageLoading(isOverlayEnabled: Bool, message: String, contentReady: Binding<Bool>) -> some View {
        modifier(DelayedPageLoadingModifier(isOverlayEnabled: isOverlayEnabled, message: message, contentReady: contentReady))
    }
}
