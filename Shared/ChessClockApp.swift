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
            ContentView(appViewModel: appViewModel)
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

    func updatePlayerTime(id: Int, from now: Date) {
        switch id {
        case 1:
            playerOne.updateTimeRemaining(from: now)
        case 2:
            playerTwo.updateTimeRemaining(from: now)
        default:
            fatalError()
        }
    }

    func updateClockEndFrom(id: Int, date: Date) {
        switch id {
        case 1:
            playerOne.updateClockEndFrom(now: date)
        case 2:
            playerTwo.updateClockEndFrom(now: date)
        default:
            fatalError()
        }
    }

    func resetPlayerTimeRemaining(id: Int) {
        switch id {
        case 1:
            playerOne.resetTimeRemaining()
        case 2:
            playerTwo.resetTimeRemaining()
        default:
            fatalError()
        }
    }

    func isPlayerOutOfTime(id: Int) -> Bool {
        switch id {
        case 1:
            return playerOne.timeRemaining <= 0
        case 2:
            return playerTwo.timeRemaining <= 0
        default:
            fatalError()
        }
    }
}
