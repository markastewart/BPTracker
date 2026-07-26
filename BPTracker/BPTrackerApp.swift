//
//  BPTrackerApp.swift
//  BPTracker
//
//  Created by Mark A Stewart on 3/25/24.
//

import SwiftUI
import SwiftData

@main
struct BPTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BPDetails.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            if let url = try! ModelContainer(for: schema, configurations: [modelConfiguration]).configurations.first?.url {
                print("SwiftData DB Path: \(url.path)")
            }
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
