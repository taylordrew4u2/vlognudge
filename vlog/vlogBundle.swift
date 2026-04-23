//
//  vlogBundle.swift
//  vlog
//

import WidgetKit
import SwiftUI

@main
struct VlogNudgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        VlogNudgeWidget()
        VlogNudgeControl()
        VlogNudgeLiveActivity()
    }
}
