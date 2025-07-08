//
//  xenon_notesApp.swift
//  xenon-notes
//
//  Created by Sekou Doumbouya on 7/7/25.
//

import SwiftUI
import SwiftData

@main
struct xenon_notesApp: App {

    @State private var appModel = AppModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recording.self,
            AudioChunk.self,
            Transcript.self,
            TranscriptSegment.self,
            Profile.self,
            AppSettings.self,
            ProcessedResult.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .modelContainer(sharedModelContainer)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
