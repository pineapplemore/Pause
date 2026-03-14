//
//  DayDetailView.swift
//  Pause
//

import SwiftUI

struct DayDetailView: View {
    let date: Date
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var recordToDelete: PuffRecord?
    
    private var dayRecords: [PuffRecord] {
        appState.records(on: date)
    }
    
    /// 按行为分组：key 为行为 id（b1/b2/…）或 "noTag"；顺序与 Behavior.ids 一致
    private var recordsByBehavior: [(behaviorKey: String, name: String, records: [PuffRecord])] {
        let grouped: [String: [PuffRecord]] = Dictionary(grouping: dayRecords) { rec in
            rec.typeIds.first(where: { Behavior.ids.contains($0) }) ?? "noTag"
        }
        let order = Behavior.ids + ["noTag"]
        return order.compactMap { key in
            guard let list = grouped[key], !list.isEmpty else { return nil }
            let name = key == "noTag" ? L10n.dayDetailNoTag(appState.isChinese) : appState.displayNameForTagId(key)
            return (key, name, list.sorted { $0.timestamp < $1.timestamp })
        }
    }
    
    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = appState.isChinese ? "M月d日" : "MMM d"
        f.locale = Locale(identifier: appState.isChinese ? "zh_Hans" : "en_US")
        return f.string(from: date)
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(L10n.dayDetailTotal(appState.isChinese))
                    Text("\(dayRecords.count)")
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                    Text(L10n.dayDetailTimes(appState.isChinese))
                }
                .font(.title3)
            }
            
            if dayRecords.isEmpty {
                Section(L10n.dayDetailList(appState.isChinese)) {
                    Text(L10n.dayDetailEmpty(appState.isChinese))
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(recordsByBehavior, id: \.behaviorKey) { group in
                    Section(group.name) {
                        ForEach(group.records) { record in
                            HStack(spacing: 12) {
                                Text(record.timestamp, style: .time)
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Text(record.recordedBehaviorName ?? appState.displayNameForTagId(record.typeIds.first ?? ""))
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    recordToDelete = record
                                } label: {
                                    Label(L10n.delete(appState.isChinese), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(dateString)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.delete(appState.isChinese), isPresented: Binding(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        )) {
            Button(L10n.cancel(appState.isChinese)) { recordToDelete = nil }
            Button(L10n.confirm(appState.isChinese), role: .destructive) {
                if let r = recordToDelete {
                    appState.deleteRecord(id: r.id)
                }
                recordToDelete = nil
            }
        } message: {
            Text(L10n.deleteRecordConfirm(appState.isChinese))
        }
    }
}

struct DayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DayDetailView(date: Date())
                .environmentObject(AppState())
        }
    }
}
