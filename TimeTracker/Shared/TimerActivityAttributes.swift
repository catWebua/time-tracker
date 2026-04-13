import ActivityKit
import Foundation

public struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startedAt: Date
        public var projectName: String
        public var projectColorHex: String
        public var isRunning: Bool
        
        public init(startedAt: Date, projectName: String, projectColorHex: String, isRunning: Bool) {
            self.startedAt = startedAt
            self.projectName = projectName
            self.projectColorHex = projectColorHex
            self.isRunning = isRunning
        }
    }

    public var taskDescription: String
    
    public init(taskDescription: String) {
        self.taskDescription = taskDescription
    }
}
