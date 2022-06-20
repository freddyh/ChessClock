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
            ContentView(
                playerOne: Player(id: 1, initialTime: 10),
                playerTwo: Player(id: 2, initialTime: 20)
            )
        }
    }
}
