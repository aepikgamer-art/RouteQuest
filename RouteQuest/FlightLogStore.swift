//
//  FlightLogStore.swift
//  RouteQuest — 100% AI-coded
//

import Foundation
import SwiftUI

/// UserDefaults-backed store of which routes the user has flown.
@MainActor
final class FlightLogStore: ObservableObject {
    @Published private(set) var flownRouteIds: Set<Int> {
        didSet { UserDefaults.standard.set(Array(flownRouteIds), forKey: "flownRouteIds") }
    }

    init() {
        let stored = UserDefaults.standard.array(forKey: "flownRouteIds") as? [Int] ?? []
        flownRouteIds = Set(stored)
    }

    func hasFlown(_ id: Int) -> Bool { flownRouteIds.contains(id) }

    func toggleFlown(_ id: Int) {
        if flownRouteIds.contains(id) { flownRouteIds.remove(id) }
        else { flownRouteIds.insert(id) }
    }

    func stats(routes: [AirlineRoute], airports: [Airport]) -> FlightStats {
        let byId = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        let airportByIata = Dictionary(uniqueKeysWithValues: airports.map { ($0.iata, $0) })
        var km = 0, airlines = Set<String>(), countries = Set<String>()
        for id in flownRouteIds {
            guard let r = byId[id] else { continue }
            km += r.distanceKm
            airlines.insert(r.airline)
            [r.from, r.to].forEach { if let a = airportByIata[$0] { countries.insert(a.country) } }
        }
        return FlightStats(totalFlown: flownRouteIds.count,
                           totalKm: km,
                           airlines: airlines.count,
                           countries: countries.count,
                           completion: routes.isEmpty ? 0 : Double(flownRouteIds.count) / Double(routes.count))
    }
}

struct FlightStats {
    let totalFlown: Int
    let totalKm: Int
    let airlines: Int
    let countries: Int
    let completion: Double

    var totalMiles: Int { Int((Double(totalKm) * 0.621371).rounded()) }
}
