//
//  PaywallView.swift
//  Puff
//
//  订阅页：年度订阅 + 3 天免费试用，明显入口。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.subscriptionTitle(appState.isChinese))
                        .font(.title2.weight(.bold))
                        .padding(.top, 8)
                    Text(L10n.trialNotice(appState.isChinese))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(L10n.subscriptionBenefits(appState.isChinese), id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.accentColor)
                                Text(benefit)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    if let product = subscriptionManager.yearlyProduct {
                        Text(product.displayPrice)
                            .font(.title.weight(.semibold))
                            .foregroundColor(Color.accentColor)
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
                    Button {
                        Task { await subscriptionManager.purchase() }
                    } label: {
                        HStack {
                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(L10n.startTrial(appState.isChinese))
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
                        Text(msg == kSubscriptionTimeoutErrorKey ? L10n.requestTimeout(appState.isChinese) : msg)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
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
}
