//
//  vlogLiveActivity.swift
//  vlog
//
//  Live Activity lock screen banner and Dynamic Island.
//  Uses VlogNudgeActivityAttributes mirrored from the main app.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

// IMPORTANT: Keep in sync with LiveActivityAttributes.swift in the main app.
// TODO: Share via target membership instead of duplicating.
struct VlogNudgeActivityAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable {
        var clipsToday: Int
        var targetClipsToday: Int
        var nextNudgeAt: Date?
        var lastClipAt: Date?
        var progressColor: ProgressColor

        enum ProgressColor: String, Codable {
            case green
            case yellow
            case orange
        }

        var progressFraction: Double {
            guard targetClipsToday > 0 else { return 0 }
            return min(1.0, Double(clipsToday) / Double(targetClipsToday))
        }
    }

    var dayKey: String
    var windowStart: Date
    var windowEnd: Date
}

// Widget-local palette — keep in sync with VNColor in DesignTokens.swift
private enum WidgetColor {
    static let accent = Color(red: 232/255, green: 85/255, blue: 58/255)  // #E8553A
}

// MARK: - Helpers

private func paceColor(_ color: VlogNudgeActivityAttributes.State.ProgressColor) -> Color {
    switch color {
    case .green:  return .green
    case .yellow: return .yellow
    case .orange: return .orange
    }
}

// MARK: - Lock Screen Banner

private struct LockScreenBannerView: View {
    let context: ActivityViewContext<VlogNudgeActivityAttributes>

    private var state: VlogNudgeActivityAttributes.State { context.state }

    var body: some View {
        VStack(spacing: 12) {
            // Top row: clip count, next nudge, record button
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(state.clipsToday)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                        Text("/\(state.targetClipsToday)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                if let next = state.nextNudgeAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("NEXT")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(next, style: .time)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(next, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Button(intent: RecordClipIntent()) {
                    Image(systemName: "video.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(WidgetColor.accent, in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Progress bar
            ProgressCapsule(
                progress: state.progressFraction,
                color: paceColor(state.progressColor),
                height: 4
            )

            // Secondary action row
            HStack(spacing: 8) {
                Button(intent: NotNowIntent()) {
                    Text("Not now")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15), in: Capsule())
                }

                Button(intent: SkipHourIntent()) {
                    Text("Skip hour")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15), in: Capsule())
                }
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .buttonStyle(.plain)
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}

// MARK: - Live Activity Widget

struct VlogNudgeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VlogNudgeActivityAttributes.self) { context in
            LockScreenBannerView(context: context)
                .activityBackgroundTint(.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded: leading — clip count
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("\(context.state.clipsToday)")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                            Text("/\(context.state.targetClipsToday)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Expanded: trailing — next nudge
                DynamicIslandExpandedRegion(.trailing) {
                    if let next = context.state.nextNudgeAt {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("NEXT")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(next, style: .time)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                    }
                }

                // Expanded: bottom — progress + actions
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressCapsule(
                            progress: context.state.progressFraction,
                            color: paceColor(context.state.progressColor),
                            height: 4
                        )

                        HStack(spacing: 8) {
                            Button(intent: RecordClipIntent()) {
                                Label("Record", systemImage: "video.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(WidgetColor.accent, in: Capsule())
                            }

                            Button(intent: NotNowIntent()) {
                                Text("Not now")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(.secondary.opacity(0.2), in: Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "video.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(paceColor(context.state.progressColor))
                    Text("\(context.state.clipsToday)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }

            } compactTrailing: {
                Text("\(context.state.clipsToday)/\(context.state.targetClipsToday)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(paceColor(context.state.progressColor))
                    .monospacedDigit()

            } minimal: {
                Text("\(context.state.clipsToday)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(paceColor(context.state.progressColor))
            }
            .keylineTint(paceColor(context.state.progressColor))
        }
    }
}

// MARK: - Previews

extension VlogNudgeActivityAttributes {
    fileprivate static var preview: VlogNudgeActivityAttributes {
        VlogNudgeActivityAttributes(
            dayKey: "2026-04-22",
            windowStart: Date(),
            windowEnd: Date().addingTimeInterval(12 * 3600)
        )
    }
}

extension VlogNudgeActivityAttributes.State {
    fileprivate static var onTrack: VlogNudgeActivityAttributes.State {
        .init(
            clipsToday: 4,
            targetClipsToday: 6,
            nextNudgeAt: Date().addingTimeInterval(780),
            lastClipAt: Date().addingTimeInterval(-1800),
            progressColor: .green
        )
    }

    fileprivate static var behind: VlogNudgeActivityAttributes.State {
        .init(
            clipsToday: 1,
            targetClipsToday: 6,
            nextNudgeAt: Date().addingTimeInterval(300),
            lastClipAt: Date().addingTimeInterval(-7200),
            progressColor: .orange
        )
    }
}

#Preview("Notification", as: .content, using: VlogNudgeActivityAttributes.preview) {
    VlogNudgeLiveActivity()
} contentStates: {
    VlogNudgeActivityAttributes.State.onTrack
    VlogNudgeActivityAttributes.State.behind
}
