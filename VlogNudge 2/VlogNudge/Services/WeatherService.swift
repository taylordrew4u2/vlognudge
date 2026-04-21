//
//  WeatherService.swift
//  VlogNudge
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherService {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService()

    private var lastCondition: String?
    private var lastCheckedAt: Date?

    private init() {}

    /// Fetch current condition and detect if it just changed.
    /// Returns a reason string if significant change, else nil.
    func checkForSignificantChange(at location: CLLocation) async -> String? {
        do {
            let weather = try await weatherService.weather(for: location)
            let condition = weather.currentWeather.condition.rawValue

            defer {
                lastCondition = condition
                lastCheckedAt = Date()
            }

            if let last = lastCondition, last != condition {
                return "weather_changed:\(last)->\(condition)"
            }
            return nil
        } catch {
            print("Weather error: \(error)")
            return nil
        }
    }

    func currentConditionString(at location: CLLocation) async -> String? {
        do {
            let weather = try await weatherService.weather(for: location)
            return weather.currentWeather.condition.rawValue
        } catch {
            return nil
        }
    }
}
