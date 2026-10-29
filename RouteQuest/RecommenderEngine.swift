//
//  RecommenderEngine.swift
//  RouteQuest — 100% AI-coded
//

import Foundation

/// Scores airline routes to recommend what you should fly next.
struct RecommenderEngine {

    /// Weighted, explainable scoring — the heart of RouteQuest.
    static func score(_ scored: ScoredRoute, flownRoutes: Set<Int>) -> Double {
        var score = 0.0
        let d = Double(scored.route.distanceKm)

        // 1. Distance component (log scale so 15,000km isn't 100x a 100km hop)
        let distanceComponent = log(1 + d / 1000) / log(1 + 16)
        score += distanceComponent * 40

        // 2. Tag appeal — iconic stuff floats to the top
        let premiumTags: Set<String> = ["Ultra-long-haul", "Record route", "A380", "Polar route",
                                        "Queen of the Skies", "Kangaroo route", "Northern lights"]
        let tagHits = scored.route.tags.filter { premiumTags.contains($0) }.count
        score += min(Double(tagHits) * 8, 16)

        // 3. Aircraft variety bonus (747s, A380s and 787s are special)
        if scored.route.aircraft.contains("747") { score += 10 }
        if scored.route.aircraft.contains("A380") { score += 8 }

        // 4. Novelty — new airlines and new countries get a boost
        // (filled in by recommend(_:flown:) below)
        return score
    }

    static func recommend(_ routes: [AirlineRoute],
                          airports: [Airport],
                          flown: Set<Int>,
                          flownAirlines: Set<String>,
                          flownCountries: Set<String>,
                          filter: RouteFilter) -> [ScoredRoute] {
        let airportByIata = Dictionary(uniqueKeysWithValues: airports.map { ($0.iata, $0) })
        var scored = routes.map { route -> ScoredRoute in
            var s = ScoredRoute(route: route,
                                 from: airportByIata[route.from],
                                 to: airportByIata[route.to])
            var base = score(s, flownRoutes: flown)

            if let f = s.from, let t = s.to {
                if !flownCountries.contains(f.country) { base += 6 }
                if !flownCountries.contains(t.country) { base += 6 }
            }
            if !flownAirlines.contains(route.airline) { base += 5 }

            // Already flown routes sink to the bottom but stay visible
            if flown.contains(route.id) { base -= 60 }

            s.score = base
            return s
        }

        if let tag = filter.tag {
            scored = scored.filter { $0.route.tags.contains(tag) }
        }
        if let region = filter.region {
            scored = scored.filter { $0.from?.region == region || $0.to?.region == region }
        }
        switch filter.length {
        case .all: break
        case .short: scored = scored.filter { $0.route.distanceKm < 1500 }
        case .long: scored = scored.filter { $0.route.distanceKm >= 1500 && $0.route.distanceKm < 10000 }
        case .ultra: scored = scored.filter { $0.route.distanceKm >= 10000 }
        }
        if !filter.showFlown {
            scored = scored.filter { !flown.contains($0.route.id) }
        }

        return scored.sorted { $0.score > $1.score }
    }
}

enum RouteLength: String, CaseIterable, Identifiable {
    case all = "Any length"
    case short = "Short (< 1,500 km)"
    case long = "Long (1,500–10,000 km)"
    case ultra = "Ultra (10,000+ km)"
    var id: String { rawValue }
}

struct RouteFilter {
    var length: RouteLength = .all
    var tag: String? = nil
    var region: String? = nil
    var showFlown: Bool = true

    static let allTags = ["Ultra-long-haul", "Record route", "A380", "Polar route", "Oceanic",
                          "Queen of the Skies", "Kangaroo route", "Northern lights",
                          "Transatlantic", "Scenic Rockies", "Glacier views", "Long-haul", "Short-haul"]
}
