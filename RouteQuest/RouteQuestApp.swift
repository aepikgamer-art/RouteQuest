//
//  RouteQuestApp.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

@main
struct RouteQuestApp: App {
    @StateObject private var log = FlightLogStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(log)
        }
    }
}
