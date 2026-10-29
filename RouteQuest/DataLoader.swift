//
//  DataLoader.swift
//  RouteQuest — 100% AI-coded
//

import Foundation

enum DataLoader {
    static func loadAirports() -> [Airport] {
        (try? load("airports.json", as: [Airport].self)) ?? []
    }

    static func loadRoutes() -> [AirlineRoute] {
        (try? load("routes.json", as: [AirlineRoute].self)) ?? []
    }

    private static func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: name.replacingOccurrences(of: ".json", with: ""),
                                        withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}
