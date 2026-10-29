//
//  RouteQuestApp.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

@main
struct RouteQuestApp: App {
    @StateObject private var log = FlightLogStore()
    @AppStorage("appearance") private var appearance: Appearance = .system

    private var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(log)
                .preferredColorScheme(colorScheme)
        }
    }
}
