//
//  vlogLiveActivity.swift
//  vlog
//
//  Created by Taylor Drew on 4/21/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct vlogAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct vlogLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: vlogAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension vlogAttributes {
    fileprivate static var preview: vlogAttributes {
        vlogAttributes(name: "World")
    }
}

extension vlogAttributes.ContentState {
    fileprivate static var smiley: vlogAttributes.ContentState {
        vlogAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: vlogAttributes.ContentState {
         vlogAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: vlogAttributes.preview) {
   vlogLiveActivity()
} contentStates: {
    vlogAttributes.ContentState.smiley
    vlogAttributes.ContentState.starEyes
}
