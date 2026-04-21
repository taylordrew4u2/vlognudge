//
//  PromptGenerator.swift
//  VlogNudge
//
//  Picks contextual prompt copy for a nudge. Kept simple and readable —
//  tune the strings here to change the voice of the whole app.
//

import Foundation

struct NudgePrompt {
    let title: String
    let body: String
}

enum PromptGenerator {

    static func prompt(for fireDate: Date,
                       reason: String,
                       settings: UserSettings,
                       lastClipDate: Date?) -> NudgePrompt {

        // Priority 1: specific contextual reasons
        if reason.hasPrefix("geofence_entry") {
            return NudgePrompt(
                title: "Just arrived somewhere",
                body: "Quick clip from the new spot?"
            )
        }
        if reason.hasPrefix("geofence_exit") {
            return NudgePrompt(
                title: "On the move",
                body: "Heading out — film a transition?"
            )
        }
        if reason == "calendar_event_ended" {
            return NudgePrompt(
                title: "That just wrapped",
                body: "How'd it go? Quick clip while it's fresh."
            )
        }
        if reason == "pre_event" {
            return NudgePrompt(
                title: "Something coming up",
                body: "Pre-event clip while you're waiting?"
            )
        }
        if reason == "workout_ended" {
            return NudgePrompt(
                title: "Post-workout moment",
                body: "Sweaty, alive, camera rolling?"
            )
        }
        if reason == "weather_changed" {
            return NudgePrompt(
                title: "Weather just shifted",
                body: "Grab a shot — B-roll gold."
            )
        }
        if reason == "doomscroll_detected" {
            return NudgePrompt(
                title: "Currently scrolling",
                body: "Flip the camera instead?"
            )
        }
        if reason == "end_of_day_recap" {
            return NudgePrompt(
                title: "Recap the day?",
                body: "One-minute voiceover about how today went."
            )
        }
        if reason == "long_gap" {
            return NudgePrompt(
                title: "Long gap",
                body: "Catch us up — what's been happening?"
            )
        }

        // Priority 2: time-of-day based
        let hour = Calendar.current.component(.hour, from: fireDate)
        let template: NudgePrompt

        switch hour {
        case 5...9:
            template = NudgePrompt(
                title: "Morning check-in",
                body: "Quick clip — how's the energy today?"
            )
        case 10...12:
            template = NudgePrompt(
                title: "Mid-morning",
                body: "What are you up to right now?"
            )
        case 13...15:
            template = NudgePrompt(
                title: "Afternoon",
                body: "Quick clip — what's going on?"
            )
        case 16...18:
            template = NudgePrompt(
                title: "Late afternoon",
                body: "Update — how's the day shaping up?"
            )
        case 19...21:
            template = NudgePrompt(
                title: "Evening",
                body: "Film a moment from tonight?"
            )
        case 22...23, 0...4:
            template = NudgePrompt(
                title: "Late night",
                body: "Quick clip before the day closes out."
            )
        default:
            template = NudgePrompt(
                title: "Time for a clip",
                body: "Quick one — what's going on?"
            )
        }

        return template
    }
}
