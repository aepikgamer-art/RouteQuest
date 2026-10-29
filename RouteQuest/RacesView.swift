//
//  RacesView.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

/// Live "race" leaderboard: real flights currently en route to an airport,
/// ranked by who's closest to landing. Powered by the Flightradar24 API.
struct RacesView: View {
    @AppStorage("fr24Key") private var apiKey = ""
    @AppStorage("preferICAO") private var preferICAO = false

    private let airports = DataLoader.loadAirports()
    @State private var destinationIata = "SFO"
    @State private var flights: [Racer] = []
    @State private var loading = false
    @State private var errorMessage: String?

    struct Racer: Identifiable {
        let flight: FlightRadarService.FR24Flight
        let kmToGo: Double
        var id: String { flight.id }
    }

    private var destination: Airport? { airports.first { $0.iata == destinationIata } }

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                    Text("Live flights racing to \(destination?.city ?? destinationIata). Data from Flightradar24 — needs an API key (Settings tab).")
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
                        RacerRow(place: idx + 1, racer: racer, preferICAO: preferICAO)
                    }
                }
            }
            .navigationTitle("Races")
            .task { await refresh() }
        }
    }

    private func refresh() async {
        guard let dest = destination else { return }
        loading = true
        errorMessage = nil
        do {
            let all = try await FlightRadarService.shared.liveFlights(
                bounds: FlightRadarService.bounds(around: dest, degrees: 8),
                apiKey: apiKey)
            let racers = all.compactMap { f -> Racer? in
                guard let lat = f.lat, let lon = f.lon else { return nil }
                guard f.destination_airport_iata == dest.iata || f.destination_airport_icao == dest.icao else { return nil }
                return Racer(flight: f, kmToGo: FlightRadarService.distanceKm(lat: lat, lon: lon, to: dest))
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
    let preferICAO: Bool

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
            Text("\(racer.flight.origin_airport_iata ?? "—") → \(racer.flight.destination_airport_iata ?? "—") · \(racer.flight.aircraft_type ?? "") \(racer.flight.registration ?? "")")
                .font(.caption)
                .foregroundStyle(.tertiary)
            HStack(spacing: 12) {
                Label(String(format: "%.0f kt", racer.flight.groundspeed_kts ?? 0), systemImage: "speedometer")
                Label(String(format: "%.0f ft", racer.flight.altitude_ft ?? 0), systemImage: "arrow.up.to.line")
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
