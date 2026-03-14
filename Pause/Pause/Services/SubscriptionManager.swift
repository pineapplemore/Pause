//
//  SubscriptionManager.swift
//  Pause
//
//  年度订阅 + 3 天试用。需在 App Store Connect 配置产品 ID 与介绍性优惠。
//

import StoreKit
import SwiftUI

/// 产品 ID，需与 App Store Connect 中创建的自动续期订阅一致，并配置 3 天免费试用
private let kYearlyProductId = "pause_yearly"

/// 购买/恢复请求超时（秒），避免无限加载
private let kPurchaseTimeoutSeconds: UInt64 = 25

/// 超时错误标记，Paywall 可据此显示本地化文案
let kSubscriptionTimeoutErrorKey = "SUBSCRIPTION_TIMEOUT"

/// 设为 true 时暂时跳过订阅校验，便于截图；正式发布需为 false 以启用 3 天试用与年订阅
private let kTemporarilyBypassSubscription = false

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var hasAccess: Bool = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private var updateListener: Task<Void, Error>?
    
    init() {
        if kTemporarilyBypassSubscription {
            hasAccess = true
        }
        updateListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updateAccess() }
    }
    
    deinit {
        updateListener?.cancel()
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == kYearlyProductId }
    }
    
    /// 试用说明文案（如 "3 天免费"）
    var trialDescription: String? {
        guard let p = yearlyProduct,
              let intro = p.subscription?.introductoryOffer else { return nil }
        switch intro.paymentMode {
        case .freeTrial:
            let period = intro.period
            if period.value == 3 && period.unit == .day { return "3 天免费" }
            return "\(period.value) \(period.unit)"
        default:
            return nil
        }
    }
    
    func loadProducts() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in self.isLoading = false } }
        do {
            let ids = [kYearlyProductId]
            let list = try await Product.products(for: ids)
            await MainActor.run { self.products = list }
            await updateAccess()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasAccess = true // 开发阶段无配置时先给通过，便于测 PDF 等
            }
        }
    }
    
    func purchase() async {
        guard let p = yearlyProduct else {
            await MainActor.run {
                errorMessage = "Product not loaded"
                hasAccess = true
            }
            return
        }
        await MainActor.run { isLoading = true; errorMessage = nil }
        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: kPurchaseTimeoutSeconds * 1_000_000_000)
            if self.isLoading {
                self.isLoading = false
                self.errorMessage = kSubscriptionTimeoutErrorKey
            }
        }
        defer {
            timeoutTask.cancel()
            Task { @MainActor in self.isLoading = false }
        }
        do {
            let result = try await p.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    await updateAccess()
                case .unverified:
                    await MainActor.run { self.errorMessage = "Purchase unverified" }
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasAccess = true
            }
        }
    }
    
    func restore() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: kPurchaseTimeoutSeconds * 1_000_000_000)
            if self.isLoading {
                self.isLoading = false
                self.errorMessage = kSubscriptionTimeoutErrorKey
            }
        }
        defer {
            timeoutTask.cancel()
            Task { @MainActor in self.isLoading = false }
        }
        do {
            try await AppStore.sync()
            await updateAccess()
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }
    
    func updateAccess() async {
        if kTemporarilyBypassSubscription {
            await MainActor.run { self.hasAccess = true }
            return
        }
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == kYearlyProductId {
                active = true
                break
            }
        }
        let newValue = active
        await MainActor.run {
            self.hasAccess = newValue
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified = result {
                    await self.updateAccess()
                }
            }
        }
    }
}
