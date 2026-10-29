//
//  FlightRadarService.swift
//  RouteQuest — 100% AI-coded
//

import Foundation
import CoreLocation

/// Unified live-flight shape shared by all providers (FR24, FlightAware...).
struct LiveFlight: Identifiable {
    let id: String
    let callsign: String?
    let aircraftType: String?
    let registration: String?
    let lat: Double?
    let lon: Double?
    let altitudeFt: Double?
    let groundspeedKts: Double?
    let originIata: String?
    let destinationIata: String?

    /// True if this flight is inbound to the given airport.
    func isArriving(at dest: Airport) -> Bool {
        destinationIata == dest.iata
    }
}

/// Client for the official Flightradar24 API (fr24api.flightradar24.com).
struct FlightRadarService {
    static let shared = FlightRadarService()
    private let base = URL(string: "https://fr24api.flightradar24.com/api")!

    struct FR24Flight: Codable {
        let fr24_id: String?
        let callsign: String?
        let lat: Double?
        let lon: Double?
        let altitude_ft: Double?
        let groundspeed_kts: Double?
        let aircraft_type: String?
        let registration: String?
        let origin_airport_iata: String?
        let destination_airport_iata: String?
        let destination_airport_icao: String?
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
    func liveFlights(bounds: String, apiKey: String) async throws -> [LiveFlight] {
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
        let flights = (try? JSONDecoder().decode([FR24Flight].self, from: data)) ?? []
        return flights.map {
            LiveFlight(id: $0.fr24_id ?? $0.callsign ?? UUID().uuidString,
                       callsign: $0.callsign,
                       aircraftType: $0.aircraft_type,
                       registration: $0.registration,
                       lat: $0.lat, lon: $0.lon,
                       altitudeFt: $0.altitude_ft,
                       groundspeedKts: $0.groundspeed_kts,
                       originIata: $0.origin_airport_iata,
                       destinationIata: $0.destination_airport_iata)
        }
    }
}

/// Great-circle distance in km between a flight and an airport.
func distanceToArrivalKm(_ flight: LiveFlight, to target: Airport) -> Double? {
    guard let lat = flight.lat, let lon = flight.lon else { return nil }
    let f = CLLocation(latitude: lat, longitude: lon)
    let t = CLLocation(latitude: target.lat, longitude: target.lon)
    return f.distance(from: t) / 1000
}

/// Bounds string (N,S,W,E) covering ±degrees around an airport.
func boundsAround(_ airport: Airport, degrees: Double) -> String {
    let n = min(90, airport.lat + degrees)
    let s = max(-90, airport.lat - degrees)
    return [String(format: "%.2f", n), String(format: "%.2f", s),
            String(format: "%.2f", airport.lon - degrees),
            String(format: "%.2f", airport.lon + degrees)].joined(separator: ",")
}
