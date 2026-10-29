//
//  RouteDetailView.swift
//  RouteQuest — 100% AI-coded
//

import SwiftUI

struct RouteDetailView: View {
    @EnvironmentObject private var log: FlightLogStore
    @AppStorage("preferICAO") private var preferICAO = false
    let scored: ScoredRoute

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text(scored.title(preferICAO: preferICAO))
                        .font(.largeTitle.bold())
                    Text(scored.route.airline)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    if let f = scored.from, let t = scored.to {
                        Text("\(f.city) (\(f.country)) → \(t.city) (\(t.country))")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section("Route info") {
                LabeledContent("Aircraft", value: scored.route.aircraft)
                LabeledContent("Dataset distance",
                               value: "\(scored.route.distanceKm) km (\(scored.distanceMiles) mi)")
                if let computed = scored.computedDistanceKm {
                    LabeledContent("Great-circle",
                                   value: "\(computed) km")
                }
                LabeledContent("Recommendation score",
                               value: String(format: "%.0f / 100", scored.score))
                if let f = scored.from, let t = scored.to {
                    LabeledContent("IATA", value: "\(f.iata) → \(t.iata)")
                    LabeledContent("ICAO", value: "\(f.icao) → \(t.icao)")
                }
            }

            Section("Vibes") {
                ForEach(scored.route.tags, id: \.self) { tag in
                    Label(tag, systemImage: "sparkle")
                }
            }

            Section {
                Button {
                    log.toggleFlown(scored.route.id)
                } label: {
                    Label(log.hasFlown(scored.route.id) ? "Mark as not flown" : "Mark as flown ✅",
                          systemImage: log.hasFlown(scored.route.id) ? "checkmark.seal.fill" : "checkmark.seal")
                }
            }
        }
        .navigationTitle(scored.subtitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let airports = DataLoader.loadAirports()
    let routes = DataLoader.loadRoutes()
    let s = RecommenderEngine.recommend(routes, airports: airports, flown: [], flownAirlines: [],
                                        flownCountries: [], filter: RouteFilter())[0]
    return NavigationStack { RouteDetailView(scored: s) }.environmentObject(FlightLogStore())
}
