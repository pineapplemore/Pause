//
//  RecordView.swift
//  Pause
//
//  主页：1～4 个方形行为按键（1 居中 / 2 并排 / 3～4 田字）+ 行为与小组件管理。
//

import SwiftUI
import WidgetKit

struct RecordView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRecorded = false
    @State private var lastRecordTime: Date?
    @State private var lastBehaviorName: String?
    @State private var showPaywall = false
    @State private var showInitialOnWidget = false
    @State private var widgetInitials: [String] = ["", "", "", ""]

    private var behaviorNames: [String] {
        appState.behaviorNames()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text(L10n.tapToRecord(appState.isChinese))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    // 1～4 个方形行为按键：1 居中 / 2 并排居中 / 3～4 田字
                    behaviorButtonsSection
                        .padding(.bottom, 28)

                    // 记录成功反馈：固定高度，避免出现时把下方模块顶下去再弹回
                    ZStack(alignment: .center) {
                        if showRecorded, let time = lastRecordTime {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("SecondaryColor"))
                                if let n = lastBehaviorName {
                                    Text("\(n) · \(time, style: .time)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(time, style: .time)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .frame(height: 28)
                    .animation(.easeOut(duration: 0.2), value: showRecorded)

                    // 行为管理 + 小组件（首字）模块
                    managementSection
                }
                .padding(.bottom, 32)
                .onAppear {
                    showInitialOnWidget = StorageService.shared.showInitialOnWidget()
                    widgetInitials = StorageService.shared.widgetBehaviorInitials()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.tabRecordFun(appState.isChinese))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text(L10n.subscribe(appState.isChinese))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(Color.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.toggleLanguage()
                    } label: {
                        Text(appState.isChinese ? "EN" : "CH")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(appState)
            }
        }
        .tint(Color.accentColor)
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var behaviorButtonsSection: some View {
        let count = behaviorNames.count
        GeometryReader { geo in
            let w = geo.size.width - 48
            let spacing: CGFloat = 8
            let side: CGFloat = count == 1 ? min(140, w) : min(100, (w - spacing) / 2)
            let contentW = side * 2 + spacing
            Group {
                if count == 1 {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        BehaviorButton(title: behaviorNames[0], size: side, colorIndex: 0) {
                            recordBehavior(id: Behavior.ids[0], name: behaviorNames[0])
                        }
                        Spacer(minLength: 0)
                    }
                } else if count == 2 {
                    HStack(spacing: spacing) {
                        Spacer(minLength: 0)
                        BehaviorButton(title: behaviorNames[0], size: side, colorIndex: 0) {
                            recordBehavior(id: Behavior.ids[0], name: behaviorNames[0])
                        }
                        BehaviorButton(title: behaviorNames[1], size: side, colorIndex: 1) {
                            recordBehavior(id: Behavior.ids[1], name: behaviorNames[1])
                        }
                        Spacer(minLength: 0)
                    }
                } else if count == 3 {
                    // 第三键与第一键竖对齐，整块居中
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        VStack(alignment: .leading, spacing: spacing) {
                            HStack(spacing: spacing) {
                                BehaviorButton(title: behaviorNames[0], size: side, colorIndex: 0) {
                                    recordBehavior(id: Behavior.ids[0], name: behaviorNames[0])
                                }
                                BehaviorButton(title: behaviorNames[1], size: side, colorIndex: 1) {
                                    recordBehavior(id: Behavior.ids[1], name: behaviorNames[1])
                                }
                            }
                            HStack(spacing: spacing) {
                                BehaviorButton(title: behaviorNames[2], size: side, colorIndex: 2) {
                                    recordBehavior(id: Behavior.ids[2], name: behaviorNames[2])
                                }
                                Color.clear.frame(width: side, height: side)
                            }
                        }
                        .frame(width: contentW, alignment: .leading)
                        Spacer(minLength: 0)
                    }
                } else {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        VStack(alignment: .leading, spacing: spacing) {
                            HStack(spacing: spacing) {
                                BehaviorButton(title: behaviorNames[0], size: side, colorIndex: 0) {
                                    recordBehavior(id: Behavior.ids[0], name: behaviorNames[0])
                                }
                                BehaviorButton(title: behaviorNames[1], size: side, colorIndex: 1) {
                                    recordBehavior(id: Behavior.ids[1], name: behaviorNames[1])
                                }
                            }
                            HStack(spacing: spacing) {
                                BehaviorButton(title: behaviorNames[2], size: side, colorIndex: 2) {
                                    recordBehavior(id: Behavior.ids[2], name: behaviorNames[2])
                                }
                                BehaviorButton(title: behaviorNames[3], size: side, colorIndex: 3) {
                                    recordBehavior(id: Behavior.ids[3], name: behaviorNames[3])
                                }
                            }
                        }
                        .frame(width: contentW, alignment: .leading)
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(width: geo.size.width, height: count == 1 ? side : (count == 2 ? side : (side * 2 + spacing)))
        }
        .frame(height: behaviorNames.count == 1 ? 120 : (behaviorNames.count == 2 ? 120 : 220))
        .padding(.horizontal, 24)
    }

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 行为：每行可编辑；第一个只能改名，其余可左滑删除；左下角「添加行为」
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.behaviorsSectionTitle(appState.isChinese))
                    .font(.headline)
                    .foregroundStyle(.primary)
                let names = appState.behaviorNames()
                List {
                    ForEach(Array(names.enumerated()), id: \.offset) { index, _ in
                        TextField("", text: Binding(
                            get: { index < appState.behaviorNames().count ? appState.behaviorNames()[index] : "" },
                            set: { appState.setBehaviorName(at: index, name: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .swipeActions(edge: .trailing) {
                            if index > 0 {
                                Button(role: .destructive) {
                                    appState.removeBehaviorSlot(at: index)
                                } label: {
                                    Text(L10n.delete(appState.isChinese))
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: CGFloat(names.count) * 52)
                HStack(spacing: 12) {
                    if names.count < Behavior.maxCount {
                        Button(L10n.addBehavior(appState.isChinese)) { appState.addBehaviorSlot() }
                            .foregroundColor(Color.accentColor)
                            .font(.subheadline.weight(.medium))
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // 小组件：仅在小组件按键右下角显示首字，需自定义；不自定义则不显示
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.widgetSectionTitle(appState.isChinese))
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack {
                    Text(L10n.showInitialOnWidget(appState.isChinese))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Toggle("", isOn: Binding(
                        get: { showInitialOnWidget },
                        set: {
                            showInitialOnWidget = $0
                            StorageService.shared.setShowInitialOnWidget($0)
                        }
                    ))
                    .labelsHidden()
                }
                if showInitialOnWidget {
                    let names = appState.behaviorNames()
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(names.enumerated()), id: \.offset) { index, _ in
                            HStack(spacing: 8) {
                                Text(index < names.count ? names[index] : "")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .frame(width: 80, alignment: .leading)
                                TextField(L10n.widgetInitialPlaceholder(appState.isChinese), text: Binding(
                                    get: { index < widgetInitials.count ? widgetInitials[index] : "" },
                                    set: { new in
                                        let one = String(new.prefix(1))
                                        if index < widgetInitials.count {
                                            widgetInitials[index] = one
                                            StorageService.shared.setWidgetBehaviorInitial(at: index, initial: one)
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                Button {
                    saveWidgetSettings()
                } label: {
                    Text(L10n.saveToWidget(appState.isChinese))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.accentColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 20)
    }

    private func saveWidgetSettings() {
        StorageService.shared.saveWidgetInitials(showInitial: showInitialOnWidget, initials: widgetInitials)
    }

    private func recordBehavior(id: String, name: String) {
        let record = PuffRecord(timestamp: Date(), typeIds: [id], recordedBehaviorName: name)
        appState.addRecord(record)
        lastRecordTime = record.timestamp
        lastBehaviorName = name
        withAnimation(.easeOut(duration: 0.2)) { showRecorded = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showRecorded = false }
        }
    }
}

private struct BehaviorButton: View {
    let title: String
    var size: CGFloat = 88
    var colorIndex: Int = 0
    let action: () -> Void

    private var mainColor: Color { Behavior.morandiColor(at: colorIndex) }
    private var darkColor: Color { Behavior.morandiDarkColor(at: colorIndex) }

    /// 若标题以数字结尾（如 "Behavior 1"、"行为1"），拆成两行：主名称 + 数字
    private var titleLine1: String {
        guard let last = title.last, last.isNumber else { return title }
        return String(title.dropLast()).trimmingCharacters(in: .whitespaces)
    }
    private var titleLine2: String? {
        guard let last = title.last, last.isNumber else { return nil }
        return String(last)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: size * 0.04) {
                Text(titleLine1)
                    .font(.system(size: size > 100 ? 13 : (size > 80 ? 11 : 10), weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let line2 = titleLine2 {
                    Text(line2)
                        .font(.system(size: size > 100 ? 14 : (size > 80 ? 12 : 11), weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: size, height: size)
            .offset(y: -size * 0.04)
                .background(
                    Image("BehaviorButtonIcon\(colorIndex + 1)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                )
                .shadow(color: mainColor.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView()
            .environmentObject(AppState())
    }
}
