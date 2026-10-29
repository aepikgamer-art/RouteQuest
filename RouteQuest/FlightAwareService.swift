//
//  FlightAwareService.swift
//  RouteQuest — 100% AI-coded
//

import Foundation

/// Client for FlightAware AeroAPI v4 (aeroapi.flightaware.com).
struct FlightAwareService {
    static let shared = FlightAwareService()
    private let base = URL(string: "https://aeroapi.flightaware.com/aeroapi")!

    struct ArrivalsResponse: Codable {
        struct FAFlight: Codable {
            let ident: String?
            let registration: String?
            let aircraft_type: String?
            let origin: FAAirport?
            let destination: FAAirport?
            let last_position: FAPosition?
        }
        struct FAAirport: Codable { let code_iata: String? }
        struct FAPosition: Codable {
            let latitude: Double?
            let longitude: Double?
            let altitude: Double?
            let groundspeed: Double?
        }
        let arrivals: [FAFlight]?
    }

    enum FAError: LocalizedError {
        case noKey, badResponse(Int)
        var errorDescription: String? {
            switch self {
            case .noKey: return "Add ur FlightAware API key in Settings first."
            case .badResponse(let code): return "FlightAware AeroAPI error (HTTP \(code))."
            }
        }
    }

    /// Live arrivals en route to an airport via AeroAPI.
    func arrivals(to airportIata: String, apiKey: String) async throws -> [LiveFlight] {
        guard !apiKey.isEmpty else { throw FAError.noKey }
        let url = base.appendingPathComponent("airports/\(airportIata)/flights/arrivals")
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw FAError.badResponse((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let decoded = try? JSONDecoder().decode(ArrivalsResponse.self, from: data)
        return (decoded?.arrivals ?? []).map {
            LiveFlight(id: $0.ident ?? UUID().uuidString,
                       callsign: $0.ident,
                       aircraftType: $0.aircraft_type,
                       registration: $0.registration,
                       lat: $0.last_position?.latitude,
                       lon: $0.last_position?.longitude,
                       altitudeFt: $0.last_position?.altitude,
                       groundspeedKts: $0.last_position?.groundspeed,
                       originIata: $0.origin?.code_iata,
                       destinationIata: $0.destination?.code_iata)
        }
    }
}
