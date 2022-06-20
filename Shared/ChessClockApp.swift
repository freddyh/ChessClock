//
//  ChessClockApp.swift
//  Shared
//
//  Created by Freddy Hernandez Jr on 6/11/22.
//

import SwiftUI

@main
struct ChessClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(players: [
                .init(id: 1, initialTime: 60),
                .init(id: 2, initialTime: 120),
            ])        }
    }
}
