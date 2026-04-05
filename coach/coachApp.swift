//
//  coachApp.swift
//  coach
//
//  Created by Mustafa Raad on 21/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("App launched")
        print("[App] Application did finish launching.")
        return true
    }
}

@main
struct coachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let sharedModelContainer: ModelContainer? = coachApp.makeModelContainer()

    private static func makeModelContainer() -> ModelContainer? {
        let schema = Schema([
            Item.self,
        ])
        let diskConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        if let container = try? ModelContainer(for: schema, configurations: [diskConfiguration]) {
            print("[App] SwiftData ModelContainer initialized on disk.")
            return container
        }

        print("[App] Failed to initialize disk ModelContainer. Falling back to in-memory store.")
        let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        if let fallbackContainer = try? ModelContainer(for: schema, configurations: [memoryConfiguration]) {
            print("[App] SwiftData ModelContainer initialized in-memory.")
            return fallbackContainer
        }

        print("[App] Failed to initialize SwiftData ModelContainer. Continuing without model container.")
        return nil
    }

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                ContentView()
                    .modelContainer(sharedModelContainer)
            } else {
                ContentView()
            }
        }
    }
}
