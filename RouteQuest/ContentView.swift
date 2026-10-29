//
//  ContentView.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

/// Liquid Glass when iOS 26+, plain otherwise.
extension View {
    @ViewBuilder
    func liquidGlassRow() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "safari") }
            RacesView()
                .tabItem { Label("Races", systemImage: "flag.checkered") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

struct DiscoverView: View {
    @EnvironmentObject private var log: FlightLogStore
    @AppStorage("preferICAO") private var preferICAO = false
    @State private var filter = RouteFilter()

    private let routes = DataLoader.loadRoutes()
    private let airports = DataLoader.loadAirports()

    private var recommendations: [ScoredRoute] {
        let flownAirlines = Set(routes.filter { log.hasFlown($0.id) }.map(\.airline))
        let flownCountries = countriesVisited()
        return RecommenderEngine.recommend(routes,
                                           airports: airports,
                                           flown: log.flownRouteIds,
                                           flownAirlines: flownAirlines,
                                           flownCountries: flownCountries,
                                           filter: filter)
    }

    private func countriesVisited() -> Set<String> {
        let airportByIata = Dictionary(uniqueKeysWithValues: airports.map { ($0.iata, $0) })
        var countries = Set<String>()
        for r in routes where log.hasFlown(r.id) {
            [r.from, r.to].forEach { if let a = airportByIata[$0] { countries.insert(a.country) } }
        }
        return countries
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatsHeader(stats: log.stats(routes: routes, airports: airports))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    Picker("Length", selection: $filter.length) {
                        ForEach(RouteLength.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Menu {
                        Button("Any vibe") { filter.tag = nil }
                        ForEach(RouteFilter.allTags, id: \.self) { tag in
                            Button(tag) { filter.tag = tag }
                        }
                    } label: {
                        Label(filter.tag ?? "Any vibe", systemImage: "sparkles")
                    }
                    Toggle("Show already flown", isOn: $filter.showFlown)
                } header: {
                    Text("Filters")
                }

                Section("Recommended for you ✈️") {
                    let recs = recommendations
                    if recs.isEmpty {
                        Text("No routes match — loosen the filters! 🌍")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(recs) { scored in
                        NavigationLink(value: scored) {
                            RouteRow(scored: scored,
                                     flown: log.hasFlown(scored.route.id),
                                     preferICAO: preferICAO)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("RouteQuest")
            .navigationDestination(for: ScoredRoute.self) { scored in
                RouteDetailView(scored: scored)
                    .environmentObject(log)
            }
        }
    }
}

struct RouteRow: View {
    let scored: ScoredRoute
    let flown: Bool
    let preferICAO: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(scored.title(preferICAO: preferICAO))
                    .font(.headline)
                Spacer()
                if flown {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                Text(String(format: "%.0f", scored.score))
                    .font(.caption.monospacedDigit())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.orange.opacity(0.2), in: Capsule())
            }
            Text(scored.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(scored.route.aircraft + " · " +
                 "\(scored.route.distanceKm) km / \(scored.distanceMiles) mi")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .liquidGlassRow()
    }
}

struct StatsHeader: View {
    let stats: FlightStats

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatPill(icon: "airplane", value: "\(stats.totalFlown)", label: "Flown")
                StatPill(icon: "point.topleft.down.curvedto.point.bottomright.up",
                         value: "\(stats.totalKm)", label: "km")
                StatPill(icon: "globe", value: "\(stats.countries)", label: "Countries")
                StatPill(icon: "building.2", value: "\(stats.airlines)", label: "Airlines")
            }
            ProgressView(value: stats.completion) {
                Text("Route completion")
                    .font(.caption)
            }
            .tint(.orange)
        }
        .padding()
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).foregroundStyle(.orange)
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .liquidGlassRow()
    }
}

#Preview {
    ContentView().environmentObject(FlightLogStore())
}
