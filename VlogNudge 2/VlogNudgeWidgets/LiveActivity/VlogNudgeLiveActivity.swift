//
//  VlogNudgeLiveActivity.swift
//  VlogNudgeWidgets
//

import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

struct VlogNudgeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VlogNudgeActivityAttributes.self) { context in
            // Lock Screen / Notification Center presentation
            LockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(context.state.clipsToday)/\(context.state.targetClipsToday)")
                            .font(.title2.bold())
                            .foregroundStyle(progressColor(context.state.progressColor))
                        Text("clips today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: RecordClipIntent()) {
                        Label("Record", systemImage: "video.circle.fill")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }

                DynamicIslandExpandedRegion(.center) {
                    if let next = context.state.nextNudgeAt {
                        VStack(spacing: 2) {
                            Text("Next nudge")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(next, style: .time)
                                .font(.subheadline.bold())
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progressFraction)
                        .tint(progressColor(context.state.progressColor))
                }
            } compactLeading: {
                Image(systemName: "video.circle.fill")
                    .foregroundStyle(progressColor(context.state.progressColor))
            } compactTrailing: {
                Text("\(context.state.clipsToday)/\(context.state.targetClipsToday)")
                    .font(.caption2.bold())
            } minimal: {
                Image(systemName: "video.circle.fill")
                    .foregroundStyle(progressColor(context.state.progressColor))
            }
        }
    }

    private func progressColor(_ c: VlogNudgeActivityAttributes.State.ProgressColor) -> Color {
        switch c {
        case .green:  return .green
        case .yellow: return .yellow
        case .orange: return .orange
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let state: VlogNudgeActivityAttributes.State

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(state.clipsToday)/\(state.targetClipsToday)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(progressColor)
                Text("clips today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Divider()
                .background(Color.white.opacity(0.3))

            VStack(alignment: .leading, spacing: 4) {
                if let next = state.nextNudgeAt {
                    Text("Next")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(next, style: .time)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("Context mode")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                if let last = state.lastClipAt {
                    Text("Last: \(last, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Button(intent: RecordClipIntent()) {
                Image(systemName: "video.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var progressColor: Color {
        switch state.progressColor {
        case .green:  return .green
        case .yellow: return .yellow
        case .orange: return .orange
        }
    }
}
