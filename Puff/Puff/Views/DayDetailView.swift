//
//  DayDetailView.swift
//  Puff
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
            
            Section(L10n.dayDetailList(appState.isChinese)) {
                if dayRecords.isEmpty {
                    Text(L10n.dayDetailEmpty(appState.isChinese))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dayRecords) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.timestamp, style: .time)
                                .font(.body.monospacedDigit())
                            if record.typeIds.isEmpty {
                                Text(L10n.dayDetailNoTag(appState.isChinese))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 6)], alignment: .leading, spacing: 4) {
                                    ForEach(record.typeIds, id: \.self) { tagId in
                                        tagLabel(tagId: tagId, record: record)
                                    }
                                }
                            }
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
    
    @ViewBuilder
    private func tagLabel(tagId: String, record: PuffRecord) -> some View {
        if let type = PuffType(rawValue: tagId) {
            Label(type.displayName(isChinese: appState.isChinese), systemImage: type.icon)
                .font(.caption)
                .foregroundStyle(type.color)
        } else if tagId.hasPrefix("custom:") {
            let name = String(tagId.dropFirst(7))
            Label(name, systemImage: "tag")
                .font(.caption)
                .foregroundStyle(Color(red: 0.4, green: 0.5, blue: 0.6))
        } else {
            Text(tagId)
                .font(.caption)
                .foregroundStyle(.secondary)
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
