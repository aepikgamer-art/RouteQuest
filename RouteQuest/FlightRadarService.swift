//
//  FlightRadarService.swift
//  RouteQuest — 100% AI-coded
//

import Foundation
import CoreLocation

/// Minimal client for the official Flightradar24 API (fr24api.flightradar24.com).
struct FlightRadarService {
    static let shared = FlightRadarService()
    private let base = URL(string: "https://fr24api.flightradar24.com/api")!

    struct FR24Flight: Codable, Identifiable {
        let fr24_id: String?
        let callsign: String?
        let lat: Double?
        let lon: Double?
        let heading: Double?
        let altitude_ft: Double?
        let groundspeed_kts: Double?
        let aircraft_type: String?
        let registration: String?
        let origin_airport_iata: String?
        let destination_airport_iata: String?
        let origin_airport_icao: String?
        let destination_airport_icao: String?

        var id: String { fr24_id ?? callsign ?? UUID().uuidString }
    }

    enum FR24Error: LocalizedError {
        case noKey, badResponse(Int)
        var errorDescription: String? {
            switch self {
            case .noKey: return "Add ur Flightradar24 API key in Settings first."
            case .badResponse(let code): return "FR24 API error (HTTP \(code))."
            }
        }
    }

    /// Fetch live flights inside a bounding box, filtered client-side.
    func liveFlights(bounds: String, apiKey: String) async throws -> [FR24Flight] {
        guard !apiKey.isEmpty else { throw FR24Error.noKey }
        var comps = URLComponents(url: base.appendingPathComponent("live/flight-positions-full"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "bounds", value: bounds)]
        var req = URLRequest(url: comps.url!)
        req.setValue("v1", forHTTPHeaderField: "Accept-Version")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw FR24Error.badResponse((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return (try? JSONDecoder().decode([FR24Flight].self, from: data)) ?? []
    }

    /// Great-circle distance in km between a flight and a point.
    static func distanceKm(lat: Double, lon: Double, to target: Airport) -> Double {
        let f = CLLocation(latitude: lat, longitude: lon)
        let t = CLLocation(latitude: target.lat, longitude: target.lon)
        return f.distance(from: t) / 1000
    }

    /// Bounds string (N,S,W,E) covering ±degrees around an airport.
    static func bounds(around airport: Airport, degrees: Double) -> String {
        let n = min(90, airport.lat + degrees)
        let s = max(-90, airport.lat - degrees)
        let w = airport.lon - degrees
        let e = airport.lon + degrees
        return [String(format: "%.2f", n), String(format: "%.2f", s),
                String(format: "%.2f", w), String(format: "%.2f", e)].joined(separator: ",")
    }
}
