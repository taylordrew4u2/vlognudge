//
//  VlogNudgeWidgetsBundle.swift
//  VlogNudgeWidgets
//

import SwiftUI
import WidgetKit

@main
struct VlogNudgeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LockScreenWidget()
        HomeScreenWidget()
        StandByWidget()
        VlogNudgeLiveActivity()
    }
}
