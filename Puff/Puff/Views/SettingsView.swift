//
//  SettingsView.swift
//  Puff
//
//  设定：小组件常用标签（最多 3 个），在小组件上点击即可带标签记录。
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedIds: [String] = []
    
    private var availableOptions: [(id: String, name: String)] {
        appState.allAvailableTagOptions()
    }
    
    private var availableIdsNotSelected: [String] {
        availableOptions.map(\.id).filter { !selectedIds.contains($0) }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(L10n.widgetFavoriteTagsSubtitle(appState.isChinese))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(8)
                        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
                    Text(L10n.widgetTagDeviceHint(appState.isChinese))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(6)
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20))
                } header: {
                    Text(L10n.widgetFavoriteTagsTitle(appState.isChinese))
                }
                
                Section(L10n.widgetSelected(appState.isChinese)) {
                    ForEach(selectedIds, id: \.self) { id in
                        HStack {
                            Text(appState.displayNameForTagId(id))
                            Spacer()
                            Button(L10n.remove(appState.isChinese)) {
                                selectedIds.removeAll { $0 == id }
                                save()
                            }
                            .foregroundColor(Color.accentColor)
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                    }
                }
                
                Section(L10n.widgetAvailable(appState.isChinese)) {
                    ForEach(availableIdsNotSelected, id: \.self) { id in
                        Button {
                            if selectedIds.count < 3 {
                                selectedIds.append(id)
                                save()
                            }
                        } label: {
                            Text(appState.displayNameForTagId(id))
                        }
                        .disabled(selectedIds.count >= 3)
                        .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(L10n.tabSettings(appState.isChinese))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedIds = StorageService.shared.widgetFavoriteTagIds()
                if !selectedIds.isEmpty && StorageService.shared.widgetFavoriteTagLabels().isEmpty {
                    let labels = selectedIds.map { appState.displayNameForTagId($0) }
                    StorageService.shared.setWidgetFavoriteTagLabels(labels)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func save() {
        StorageService.shared.setWidgetFavoriteTagIds(selectedIds)
        let labels = selectedIds.map { appState.displayNameForTagId($0) }
        StorageService.shared.setWidgetFavoriteTagLabels(labels)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
