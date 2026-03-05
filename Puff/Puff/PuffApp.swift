//
//  PuffApp.swift
//  Puff
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
                    if url.scheme == "puff", url.host == "record" {
                        var typeIds: [String] = []
                        if let comp = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let items = comp.queryItems,
                           let tag = items.first(where: { $0.name == "tag" })?.value, !tag.isEmpty {
                            typeIds = [tag]
                        }
                        let record = PuffRecord(timestamp: Date(), typeIds: typeIds)
                        StorageService.shared.addRecord(record)
                        appState.refresh()
                        UserDefaults.standard.set(true, forKey: "Puff.justOpenedFromWidget")
                    }
                }
        }
    }
}
