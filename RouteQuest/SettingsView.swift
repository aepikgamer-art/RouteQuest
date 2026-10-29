//
//  SettingsView.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }
}

struct SettingsView: View {
    @AppStorage("provider") private var provider: DataProvider = .fr24
    @AppStorage("fr24Key") private var fr24Key = ""
    @AppStorage("flightAwareKey") private var faKey = ""
    @AppStorage("preferICAO") private var preferICAO = false
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Provider", selection: $provider) {
                        ForEach(DataProvider.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Flight data")
                } footer: {
                    Text("Races pulls live flights from whichever provider u pick. Both keys can be set — the app uses the selected one.")
                }

                Section {
                    SecureField("API key", text: $fr24Key)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Link(destination: URL(string: "https://fr24api.flightradar24.com")!) {
                        Label("Get a key at fr24api.flightradar24.com", systemImage: "key.radiowaves.forward")
                    }
                } header: {
                    Text("Flightradar24 API")
                } footer: {
                    Text("Stored only on ur device.")
                }

                Section {
                    SecureField("API key", text: $faKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Link(destination: URL(string: "https://www.flightaware.com/aeroapi/")!) {
                        Label("Get a key at flightaware.com/aeroapi", systemImage: "key.radiowaves.forward")
                    }
                } header: {
                    Text("FlightAware AeroAPI")
                } footer: {
                    Text("Alternative if u don't wanna use FR24. Stored only on ur device.")
                }

                Section("Airport codes") {
                    Picker("Code style", selection: $preferICAO) {
                        Text("IATA (ATL)").tag(false)
                        Text("ICAO (KATL)").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("About") {
                    LabeledContent("App", value: "RouteQuest 1.4")
                    Label("Liquid Glass design on iOS 26", systemImage: "drop")
                    Label("100% coded by AI. No human wrote any of it. 🤖", systemImage: "brain")
                    Link(destination: URL(string: "https://github.com/aepikgamer-art/RouteQuest")!) {
                        Label("GitHub repository", systemImage: "link")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
