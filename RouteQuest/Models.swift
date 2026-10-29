//
//  Models.swift
//  RouteQuest — 100% AI-coded
//

import Foundation

struct Airport: Codable, Identifiable, Hashable {
    let iata: String
    let name: String
    let city: String
    let country: String
    let region: String
    let lat: Double
    let lon: Double

    var id: String { iata }
}

struct AirlineRoute: Codable, Identifiable, Hashable {
    let id: Int
    let airline: String
    let from: String
    let to: String
    let distanceKm: Int
    let aircraft: String
    let tags: [String]
}

/// A route plus the airports resolved + recommendation score.
struct ScoredRoute: Identifiable, Hashable {
    let route: AirlineRoute
    var from: Airport?
    var to: Airport?
    var score: Double = 0

    var id: Int { route.id }

    var title: String { "\(route.from) → \(route.to)" }
    var subtitle: String { route.airline }

    var distanceMiles: Int { Int((Double(route.distanceKm) * 0.621371).rounded()) }

    func haversine(from: Airport, to: Airport) -> Double {
        let r = 6371.0
        let dLat = (to.lat - from.lat) * .pi / 180
        let dLon = (to.lon - from.lon) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(from.lat * .pi / 180) * cos(to.lat * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * atan2(sqrt(a), sqrt(1 - a))
    }

    /// Great-circle distance between resolved airports (sanity check vs dataset).
    var computedDistanceKm: Int? {
        guard let f = from, let t = to else { return nil }
        return Int(haversine(from: f, to: t).rounded())
    }
}
