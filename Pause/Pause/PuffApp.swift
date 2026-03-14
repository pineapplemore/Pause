//
//  PuffApp.swift
//  Pause
//

import SwiftUI

@main
struct PuffApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                ContentView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environmentObject(appState)
            }
            .onOpenURL { url in
                    if url.scheme == "pause", url.host == "record" {
                        var typeIds: [String] = []
                        if let comp = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let items = comp.queryItems,
                           let tag = items.first(where: { $0.name == "tag" })?.value, !tag.isEmpty {
                            typeIds = [tag]
                        }
                        if typeIds.isEmpty { typeIds = [Behavior.ids[0]] }
                        let name = appState.displayNameForTagId(typeIds[0])
                        let record = PuffRecord(timestamp: Date(), typeIds: typeIds, recordedBehaviorName: name)
                        StorageService.shared.addRecord(record)
                        appState.refresh()
                        UserDefaults.standard.set(true, forKey: "Pause.justOpenedFromWidget")
                    }
                }
        }
    }
}
