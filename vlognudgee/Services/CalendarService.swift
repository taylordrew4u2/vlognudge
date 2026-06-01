//
//  CalendarService.swift
//  VlogNudge
//

import Foundation
import EventKit
import os
import SwiftData

@MainActor
final class CalendarService {
    static let shared = CalendarService()
    private let store = EKEventStore()

    private init() {}

    func requestAccess() async {
        do {
            if #available(iOS 17.0, *) {
                _ = try await store.requestFullAccessToEvents()
            } else {
                _ = try await store.requestAccess(to: .event)
            }
        } catch {
            Logger.calendar.error("Calendar access error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func upcomingEvent(within minutes: Int = 15) -> EKEvent? {
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(minutes * 60))
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.startDate > now }
            .min { $0.startDate < $1.startDate }
    }

    func eventJustEnded(withinLastMinutes minutes: Int = 5) -> EKEvent? {
        let now = Date()
        let start = now.addingTimeInterval(-TimeInterval(minutes * 60))
        let predicate = store.predicateForEvents(withStart: start, end: now, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.endDate <= now && $0.endDate > start }
            .max { $0.endDate < $1.endDate }
    }

    /// Called periodically (from scheduler) to detect event-end moments.
    func checkForEventTriggers() async {
        let context = SharedModelContainer.backgroundContext()

        if eventJustEnded() != nil {
            await NudgeScheduler.shared.evaluateContextTrigger(
                reason: "calendar_event_ended",
                context: context
            )
        }

        if let upcoming = upcomingEvent() {
            let minutesUntil = Int(upcoming.startDate.timeIntervalSinceNow / 60)
            if minutesUntil <= 15 && minutesUntil >= 5 {
                await NudgeScheduler.shared.evaluateContextTrigger(
                    reason: "pre_event",
                    context: context
                )
            }
        }
    }
}
