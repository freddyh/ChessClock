//
//  ChessClockApp.swift
//  Shared
//
//  Created by Freddy Hernandez Jr on 6/11/22.
//

import SwiftUI

@main
struct ChessClockApp: App {
    @StateObject var appViewModel: AppViewModel = .init(
        playerOne: Player(id: 1, initialTime: 10),
        playerTwo: Player(id: 2, initialTime: 20)
    )

    var body: some Scene {
        WindowGroup {
            ContentView(
                playerOne: appViewModel.playerOne,
                playerTwo: appViewModel.playerTwo
            )
        }
    }
}

class AppViewModel: ObservableObject {
    @Published var playerOne: Player
    @Published var playerTwo: Player

    init(playerOne: Player, playerTwo: Player) {
        self.playerOne = playerOne
        self.playerTwo = playerTwo
    }
}
