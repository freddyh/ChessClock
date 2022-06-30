//
//  ChessClockApp.swift
//  Shared
//
//  Created by Freddy Hernandez Jr on 6/11/22.
//

import ComposableArchitecture
import SwiftUI

@main
struct ChessClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentViewComposable(
                store: .init(
                    initialState: .init(
                        playerOne: Player(id: 1, initialTime: 10),
                        playerTwo: Player(id: 1, initialTime: 10),
                        gameState: .ready
                    ),
                reducer: appReducer,
                    environment: AppEnvironment.init(mainQueue: .main)
                )
            )
        }
    }
}

struct AppState: Equatable {
    var playerOne: Player
    var playerTwo: Player
    var activePlayer: Int?
    var gameState: GameState
    var lastClockStart: Date?
}

enum AppAction: Equatable {
    case playerClockButtonTapped(Int)
    case settingsButtonTapped
    case gameStateButtonTapped
    case pauseGame
    case playGame
    case resetGame
    case playerTimeUpdated(Int)
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
//    var numberFact: (Int) -> Effect<String, ApiError>
}


let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .playerClockButtonTapped(let id):
        switch state.gameState {
        case .ready:
            // give control to other player
            state.gameState = .active
            let date = Date()
            switch id {
            case 1:
                state.playerOne.updateClockEndFrom(now: date)
            case 2:
                state.playerTwo.updateClockEndFrom(now: date)
            default:
                fatalError()
            }
            state.activePlayer = id

        case .active:
            // must be the active player to give control to other player
            guard state.activePlayer != id else { break }
            let date = Date()
            if state.gameState == .paused { state.gameState = .active }
            switch id {
            case 1:
                state.playerOne.updateClockEndFrom(now: date)
            case 2:
                state.playerTwo.updateClockEndFrom(now: date)
            default:
                fatalError()
            }
            state.activePlayer = id
        case .paused:
            // give control to other player
            state.gameState = .active
            let date = Date()
            switch id {
            case 1:
                state.playerOne.updateClockEndFrom(now: date)
            case 2:
                state.playerTwo.updateClockEndFrom(now: date)
            default:
                fatalError()
            }
            state.activePlayer = id
        case .outOfTime:
            break
        }
        return Effect.none
    case .settingsButtonTapped:
        return Effect.none
    case .gameStateButtonTapped:
        return Effect.none
    case .pauseGame:
        state.gameState = .paused
        return Effect.none
    case .playGame:
        state.lastClockStart = Date()

        let date = Date()
        switch state.activePlayer {
        case 1:
            state.playerOne.updateClockEndFrom(now: date)
        case 2:
            state.playerTwo.updateClockEndFrom(now: date)
        default:
            fatalError()
        }


        return Effect.none
    case .resetGame:
        state.activePlayer = nil
        state.playerOne.resetTimeRemaining()
        state.playerTwo.resetTimeRemaining()
        state.gameState = .ready
        state.lastClockStart = nil

        return Effect.none
    case .playerTimeUpdated(let id):
        let now = Date()
        switch id {
        case 1:
            state.playerOne.updateTimeRemaining(from: now)
        case 2:
            state.playerTwo.updateTimeRemaining(from: now)
        default:
            fatalError()
        }

        if state.playerTwo.timeRemaining <= 0 || state.playerOne.timeRemaining <= 0 {
            state.gameState = .outOfTime
        }
        return .none
    }
}
