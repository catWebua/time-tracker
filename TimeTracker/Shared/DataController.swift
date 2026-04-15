import Foundation
import SwiftData

@MainActor
final class DataController {
    static let shared = DataController()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            Project.self,
            TimeEntry.self
        ])
        
        // Configuration for the shared store in App Group
        let appGroupID = "group.catWebua.TimeTracker"
        let storeURL: URL
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            storeURL = appGroupURL.appendingPathComponent("TimeTracker.store")
        } else {
            print("WARNING: Could not find App Group container for \(appGroupID). Falling back to local documents directory.")
            storeURL = URL.documentsDirectory.appendingPathComponent("TimeTracker.store")
        }
        let modelConfiguration = ModelConfiguration(
            "TimeTracker",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("DEBUG: SwiftData ModelContainer initialized in App Group: \(storeURL.path)")
        } catch {
            fatalError("CRITICAL: Could not create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    static var sharedContainer: ModelContainer {
        return shared.container
    }
}
