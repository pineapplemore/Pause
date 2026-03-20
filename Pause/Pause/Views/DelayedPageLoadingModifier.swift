//
//  DelayedPageLoadingModifier.swift
//  Pause
//
//  Tab 首屏较重时：约 0.35s 后仍无「就绪」信号则显示转圈，减轻卡顿感。
//

import SwiftUI

/// 在 `content` 上叠一层延迟加载提示；在列表底部 `Color.clear.onAppear { contentReady = true }` 表示首屏已挂上。
struct DelayedPageLoadingModifier: ViewModifier {
    /// 为 false 时不显示（例如未订阅时日历/统计已有蒙层）
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
