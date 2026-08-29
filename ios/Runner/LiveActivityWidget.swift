import ActivityKit
import WidgetKit
import SwiftUI

// Make sure this matches the data you pass from Flutter
struct BookingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state properties if needed
    }
    
    // Static properties
    var groundName: String
    var startTime: String
}

@available(iOS 16.1, *)
struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BookingActivityAttributes.self) { context in
            // Lock screen / Banner UI
            VStack(alignment: .leading) {
                Text("Upcoming Match")
                    .font(.headline)
                    .foregroundColor(.green)
                Text(context.attributes.groundName)
                    .font(.subheadline)
                HStack {
                    Text("Starts at:")
                    Text(context.attributes.startTime)
                        .fontWeight(.bold)
                }
            }
            .padding()
            
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Match")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startTime)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.groundName)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Get Ready!")
                }
            } compactLeading: {
                Text("🏏")
            } compactTrailing: {
                Text("Soon")
            } minimal: {
                Text("🏏")
            }
        }
    }
}
