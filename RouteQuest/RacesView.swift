//
//  RacesView.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

enum DataProvider: String, CaseIterable, Identifiable {
    case fr24 = "Flightradar24"
    case flightaware = "FlightAware"
    var id: String { rawValue }
}

/// Live "race" leaderboard: real flights currently en route to an airport,
/// ranked by who's closest to landing. Powered by FR24 or FlightAware.
struct RacesView: View {
    @AppStorage("provider") private var provider: DataProvider = .fr24
    @AppStorage("fr24Key") private var fr24Key = ""
    @AppStorage("flightAwareKey") private var faKey = ""
    @AppStorage("preferICAO") private var preferICAO = false

    private let airports = DataLoader.loadAirports()
    @State private var destinationIata = "SFO"
    @State private var flights: [Racer] = []
    @State private var loading = false
    @State private var errorMessage: String?

    struct Racer: Identifiable {
        let flight: LiveFlight
        let kmToGo: Double
        var id: String { flight.id }
    }

    private var destination: Airport? { airports.first { $0.iata == destinationIata } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Data provider", selection: $provider) {
                        ForEach(DataProvider.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Race finish line", selection: $destinationIata) {
                        ForEach(airports) { a in
                            Text("\(a.code(preferICAO: preferICAO)) — \(a.city)")
                                .tag(a.iata)
                        }
                    }
                    Button {
                        Task { await refresh() }
                    } label: {
                        Label(loading ? "Loading…" : "Refresh race", systemImage: "arrow.clockwise")
                    }
                    .disabled(loading)
                } header: {
                    Text("🏁 Race — who lands first?")
                } footer: {
                    Text("Live flights racing to \(destination?.city ?? destinationIata) via \(provider == .fr24 ? "Flightradar24" : "FlightAware AeroAPI"). Add an API key in Settings.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Leaderboard") {
                    if flights.isEmpty && !loading {
                        Text("No live flights inbound right now — try another airport ✈️")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(flights.enumerated()), id: \.element.id) { idx, racer in
                        RacerRow(place: idx + 1, racer: racer)
                    }
                }
            }
            .navigationTitle("Races")
            .task { await refresh() }
            .onChange(of: provider) { _ in Task { await refresh() } }
        }
    }

    private func refresh() async {
        guard let dest = destination else { return }
        loading = true
        errorMessage = nil
        do {
            let live: [LiveFlight]
            switch provider {
            case .fr24:
                live = try await FlightRadarService.shared.liveFlights(
                    bounds: boundsAround(dest, degrees: 8),
                    apiKey: fr24Key)
            case .flightaware:
                live = try await FlightAwareService.shared.arrivals(to: dest.iata, apiKey: faKey)
            }
            let racers = live.compactMap { f -> Racer? in
                guard f.isArriving(at: dest),
                      let km = distanceToArrivalKm(f, to: dest) else { return nil }
                return Racer(flight: f, kmToGo: km)
            }
            .sorted { $0.kmToGo < $1.kmToGo }
            flights = racers
        } catch {
            errorMessage = error.localizedDescription
            flights = []
        }
        loading = false
    }
}

struct RacerRow: View {
    let place: Int
    let racer: RacesView.Racer

    private var medal: String {
        switch place {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(place)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(medal).font(.headline)
                Text(racer.flight.callsign ?? "???")
                    .font(.headline.monospaced())
                Spacer()
                Text(String(format: "%.0f km to go", racer.kmToGo))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("\(racer.flight.originIata ?? "—") → \(racer.flight.destinationIata ?? "—") · \(racer.flight.aircraftType ?? "") \(racer.flight.registration ?? "")")
                .font(.caption)
                .foregroundStyle(.tertiary)
            HStack(spacing: 12) {
                Label(String(format: "%.0f kt", racer.flight.groundspeedKts ?? 0), systemImage: "speedometer")
                Label(String(format: "%.0f ft", racer.flight.altitudeFt ?? 0), systemImage: "arrow.up.to.line")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .liquidGlassRow()
    }
}

#Preview {
    RacesView()
}
