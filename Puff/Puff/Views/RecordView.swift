//
//  RecordView.swift
//  Puff
//

import SwiftUI

struct RecordView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTagIds: Set<String> = []
    @State private var showRecorded = false
    @State private var lastRecordTime: Date?
    @State private var showCustomTagSheet = false
    @State private var customTagInput = ""
    @State private var tagToRemoveFromList: PuffType?
    @State private var customTagToRemove: String?
    @AppStorage("Puff.showTagDeleteButtons") private var showTagDeleteButtons = false
    @State private var showRetroactiveSheet = false
    @State private var customMinutesInput = ""
    @State private var milestoneToShow: Int?
    @State private var recordButtonScale: CGFloat = 1.0
    @State private var showPaywall = false
    
    private var visibleDefaultTypes: [PuffType] {
        PuffType.allCases.filter { !appState.deletedDefaultTagIds.contains($0.rawValue) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    Button {
                        recordPuff()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.608, green: 0.816, blue: 0.733),
                                            Color(red: 0.52, green: 0.72, blue: 0.65)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .shadow(color: Color(red: 0.608, green: 0.816, blue: 0.733).opacity(0.35), radius: 16, x: 0, y: 8)
                            Image("RecordPuffIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(recordButtonScale)
                    
                    if showRecorded, let t = lastRecordTime {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("SecondaryColor"))
                            Text("\(t, style: .time)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                    
                    // 补登暂时不用
                    // Button {
                    //     showRetroactiveSheet = true
                    // } label: {
                    //     Text(L10n.retroactiveLog(appState.isChinese))
                    //         .font(.subheadline.weight(.medium))
                    //         .foregroundColor(Color.accentColor)
                    // }
                    // .padding(.top, 4)
                    
                    // 「标签（可多选）」居左，右侧为「自定义」按钮
                    HStack(spacing: 8) {
                        Text(L10n.tagMultiSelect(appState.isChinese))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            customTagInput = ""
                            showCustomTagSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.caption2)
                                Text(L10n.customTag(appState.isChinese))
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.accentColor, lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    
                    Toggle(isOn: $showTagDeleteButtons) {
                        Text(L10n.showTagDeleteButtons(appState.isChinese))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .tint(Color.accentColor)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 98))], spacing: 10) {
                            ForEach(visibleDefaultTypes, id: \.rawValue) { type in
                                HStack(spacing: 4) {
                                    TypeChip(
                                        type: type,
                                        isSelected: selectedTagIds.contains(type.rawValue),
                                        isChinese: appState.isChinese,
                                        action: { toggleTag(id: type.rawValue) }
                                    )
                                    if showTagDeleteButtons {
                                        Button {
                                            tagToRemoveFromList = type
                                            customTagToRemove = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.body)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            ForEach(appState.customTagNames, id: \.self) { name in
                                HStack(spacing: 4) {
                                    CustomTagChip(
                                        name: name,
                                        isSelected: selectedTagIds.contains("custom:\(name)"),
                                        action: { toggleTag(id: "custom:\(name)") }
                                    )
                                    if showTagDeleteButtons {
                                        Button {
                                            customTagToRemove = name
                                            tagToRemoveFromList = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.body)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(maxHeight: 280)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
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
            .sheet(isPresented: $showCustomTagSheet) {
                customTagSheet
            }
            // 补登暂时不用
            // .sheet(isPresented: $showRetroactiveSheet) {
            //     retroactiveSheet
            // }
            .alert(
                milestoneToShow.map { L10n.milestoneTitle(appState.isChinese, $0) } ?? "",
                isPresented: Binding(
                    get: { milestoneToShow != nil },
                    set: { if !$0 { milestoneToShow = nil } }
                )
            ) {
                Button(L10n.confirm(appState.isChinese)) { milestoneToShow = nil }
            } message: {
                if let m = milestoneToShow {
                    Text(L10n.milestoneMessage(appState.isChinese, m))
                }
            }
            .alert(L10n.removeTagFromList(appState.isChinese), isPresented: Binding(
                get: { tagToRemoveFromList != nil || customTagToRemove != nil },
                set: { if !$0 { tagToRemoveFromList = nil; customTagToRemove = nil } }
            )) {
                Button(L10n.cancel(appState.isChinese)) {
                    tagToRemoveFromList = nil
                    customTagToRemove = nil
                }
                Button(L10n.confirm(appState.isChinese)) {
                    if let t = tagToRemoveFromList {
                        appState.removeDefaultTagFromList(rawValue: t.rawValue)
                        selectedTagIds.remove(t.rawValue)
                    }
                    if let name = customTagToRemove {
                        appState.removeCustomTag(name: name)
                        selectedTagIds.remove("custom:\(name)")
                    }
                    tagToRemoveFromList = nil
                    customTagToRemove = nil
                }
            }
        }
        .tint(Color.accentColor)
        .navigationViewStyle(.stack)
        .onAppear {
            if let id = appState.lastRecordedId, let r = appState.record(byId: id) {
                selectedTagIds = Set(r.typeIds)
            }
            if UserDefaults.standard.bool(forKey: "Puff.justOpenedFromWidget") {
                UserDefaults.standard.set(false, forKey: "Puff.justOpenedFromWidget")
                withAnimation(.easeOut(duration: 0.12)) { recordButtonScale = 1.15 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.18)) { recordButtonScale = 1.0 }
                }
            }
        }
    }
    
    private func recordPuff(at date: Date = Date()) {
        let record = PuffRecord(
            timestamp: date,
            typeIds: Array(selectedTagIds)
        )
        appState.addRecord(record)
        if let m = appState.checkMilestoneAfterRecord() {
            milestoneToShow = m
        }
        lastRecordTime = record.timestamp
        withAnimation(.easeOut(duration: 0.2)) { showRecorded = true }
        selectedTagIds = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showRecorded = false }
        }
    }
    
    private var retroactiveSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text(L10n.retroactiveTitle(appState.isChinese))
                    .font(.headline)
                    .padding(.top, 20)
                Button {
                    recordPuff(at: Date().addingTimeInterval(-5 * 60))
                    showRetroactiveSheet = false
                } label: {
                    Text(L10n.minutesAgo(appState.isChinese, 5))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                Button {
                    recordPuff(at: Date().addingTimeInterval(-10 * 60))
                    showRetroactiveSheet = false
                } label: {
                    Text(L10n.minutesAgo(appState.isChinese, 10))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                HStack {
                    TextField(L10n.customMinutesPlaceholder(appState.isChinese), text: $customMinutesInput)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button(L10n.confirm(appState.isChinese)) {
                        if let m = Int(customMinutesInput), m > 0, m <= 1440 {
                            recordPuff(at: Date().addingTimeInterval(-Double(m) * 60))
                            showRetroactiveSheet = false
                        }
                    }
                    .foregroundColor(Color.accentColor)
                }
                .padding(.horizontal)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.cancel(appState.isChinese)) { showRetroactiveSheet = false }
                }
            }
        }
    }
    
    private var customTagSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField(L10n.customTagPlaceholder(appState.isChinese), text: $customTagInput)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                HStack(spacing: 16) {
                    Button(L10n.cancel(appState.isChinese)) {
                        showCustomTagSheet = false
                    }
                    .foregroundColor(Color("SecondaryColor"))
                    Spacer()
                    Button(L10n.confirm(appState.isChinese)) {
                        let name = customTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty {
                            appState.addCustomTag(name: name)
                            toggleTag(id: "custom:\(name)")
                        }
                        showCustomTagSheet = false
                    }
                    .foregroundColor(Color.accentColor)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationTitle(L10n.addCustomTag(appState.isChinese))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// 点击标签：若刚记录过则把标签关联到上一条；否则只更新下次记录的预选
    private func toggleTag(id: String) {
        if let lastId = appState.lastRecordedId, let record = appState.record(byId: lastId) {
            var ids = record.typeIds
            if ids.contains(id) {
                ids.removeAll { $0 == id }
            } else {
                ids.append(id)
            }
            appState.updateRecordTags(id: lastId, typeIds: ids)
            selectedTagIds = Set(ids)
        } else {
            if selectedTagIds.contains(id) {
                selectedTagIds.remove(id)
            } else {
                selectedTagIds.insert(id)
            }
        }
    }
}

struct TypeChip: View {
    let type: PuffType
    let isSelected: Bool
    let isChinese: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName(isChinese: isChinese))
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : type.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? type.color : type.color.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomTagChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    private var color: Color { Color(red: 0.4, green: 0.5, blue: 0.6) }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.caption)
                Text(name)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
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
