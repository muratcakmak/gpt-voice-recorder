//
//  voice_recorderApp.swift
//  voice-recorder
//
//  Created by Oguzhan Cakmak on 16.03.2023.
//

import SwiftUI

@main
struct voice_recorderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
