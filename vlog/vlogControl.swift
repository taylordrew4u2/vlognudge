//
//  vlogControl.swift
//  vlog
//

import AppIntents
import SwiftUI
import WidgetKit

struct VlogNudgeControl: ControlWidget {
    static let kind: String = "com.taylordrew.vlognudge.record-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: RecordClipIntent()) {
                Label("Record Vlog", systemImage: "video.circle.fill")
            }
        }
        .displayName("Record Vlog")
        .description("Open VlogNudge to record a clip.")
    }
}
