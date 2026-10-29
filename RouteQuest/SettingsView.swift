//
//  SettingsView.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("fr24Key") private var apiKey = ""
    @AppStorage("preferICAO") private var preferICAO = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Link(destination: URL(string: "https://fr24api.flightradar24.com")!) {
                        Label("Get a key at fr24api.flightradar24.com", systemImage: "key.radiowaves.forward")
                    }
                } header: {
                    Text("Flightradar24 API")
                } footer: {
                    Text("Used by the Races tab to pull live flight data. Stored only on ur device.")
                }

                Section("Airport codes") {
                    Picker("Code style", selection: $preferICAO) {
                        Text("IATA (ATL)").tag(false)
                        Text("ICAO (KATL)").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("About") {
                    LabeledContent("App", value: "RouteQuest 1.3")
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
