//
//  PaywallView.swift
//  Puff
//
//  订阅页：满足 3.1.2(c) 账单金额最显著，试用为次要；含订阅名称、周期、价格及 EULA/隐私链接。
//

import SwiftUI
import StoreKit

/// 替换为你在 Netlify 部署后的实际地址（支持与隐私页）
private let kLegalBaseURL = "https://stirring-strudel-e1d811.netlify.app"

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. 订阅名称（服务标题）
                    Text(L10n.subscriptionName(appState.isChinese))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    // 2. 账单金额：最显著（3.1.2(c) 要求）
                    if let product = subscriptionManager.yearlyProduct {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.displayPrice)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color.accentColor)
                            Text(appState.isChinese ? "/年" : "/year")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        // 试用说明：次要位置、较小字号
                        Text(L10n.trialNotice(appState.isChinese))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if !subscriptionManager.isLoading {
                        Text(L10n.productsLoadFailed(appState.isChinese))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await subscriptionManager.loadProducts() }
                        } label: {
                            Text(L10n.retry(appState.isChinese))
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 3. 订阅周期与内容说明（3.1.2(c) 要求）
                    Text(L10n.subscriptionLength(appState.isChinese))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(L10n.subscriptionBenefits(appState.isChinese), id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.accentColor)
                                Text(benefit)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // 4. 主操作按钮（文案不突出“免费试用”，避免比价格更显眼）
                    Button {
                        Task { await subscriptionManager.purchase() }
                    } label: {
                        HStack {
                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(L10n.subscribe(appState.isChinese))
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(subscriptionManager.isLoading || subscriptionManager.yearlyProduct == nil)
                    .buttonStyle(.plain)
                    
                    Button {
                        Task { await subscriptionManager.restore() }
                    } label: {
                        Text(L10n.restorePurchases(appState.isChinese))
                            .font(.subheadline)
                            .foregroundColor(Color.accentColor)
                    }
                    .disabled(subscriptionManager.isLoading || subscriptionManager.yearlyProduct == nil)
                    .buttonStyle(.plain)
                    
                    if let msg = subscriptionManager.errorMessage {
                        Text(userFacingErrorMessage(msg))
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 5. EULA 与隐私政策链接（3.1.2(c) 要求）
                    VStack(alignment: .leading, spacing: 8) {
                        if let terms = URL(string: kLegalBaseURL) {
                            Link(destination: terms) {
                                Text(L10n.termsOfUse(appState.isChinese))
                                    .font(.caption)
                                    .foregroundColor(Color.accentColor)
                            }
                        }
                        if let privacy = URL(string: kLegalBaseURL + "#privacy") {
                            Link(destination: privacy) {
                                Text(L10n.privacyPolicy(appState.isChinese))
                                    .font(.caption)
                                    .foregroundColor(Color.accentColor)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.cancel(appState.isChinese)) { dismiss() }
                        .foregroundColor(Color.accentColor)
                }
            }
        }
        .onChange(of: subscriptionManager.hasAccess) { hasAccess in
            if hasAccess { dismiss() }
        }
    }
    
    private func userFacingErrorMessage(_ message: String) -> String {
        if message == kSubscriptionTimeoutErrorKey {
            return L10n.requestTimeout(appState.isChinese)
        }
        if message == "Product not loaded" {
            return L10n.productsLoadFailed(appState.isChinese)
        }
        if message.contains("unverified") || message.contains("network") {
            return appState.isChinese ? "购买验证失败，请稍后重试或使用「恢复购买」" : "Purchase could not be verified. Try again later or use Restore."
        }
        return appState.isChinese ? "操作失败，请重试或使用「恢复购买」" : "Something went wrong. Please retry or use Restore."
    }
}
