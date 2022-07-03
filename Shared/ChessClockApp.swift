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
                environment: .init(mainQueue: .main)
                )
            )
        }
    }
}

struct AppState: Equatable {
    var playerOne: Player
    var playerTwo: Player
    var gameState: GameState
}

enum AppAction: Equatable {
    case playerClockButtonTapped(Int)
    case settingsButtonTapped
    case gameStateButtonTapped
    case pauseGame
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
            let date = Date()
            switch id {
            case 1:
                state.playerOne.updateClockEndFrom(now: date)
            case 2:
                state.playerTwo.updateClockEndFrom(now: date)
            default:
                fatalError()
            }
            state.gameState = .active(playerId: id)
            return .none

        case .active:
            // must be the active player to give control to other player
            switch state.gameState {
            case .paused(playerId: let previous):
                if previous != id {
                    print("active player changed between pause")
                }
                state.gameState = .active(playerId: id)
            case .active(playerId: let activePlayer):
                if activePlayer == id { return .none }
            default:
                break
            }

            let date = Date()
            switch id {
            case 1:
                state.playerOne.updateClockEndFrom(now: date)
            case 2:
                state.playerTwo.updateClockEndFrom(now: date)
            default:
                fatalError()
            }
            state.gameState = .active(playerId: id)
            return .none

        case .paused:
            // give control to other player
            let date = Date()
            switch id {
            case 1:
                state.playerOne.updateClockEndFrom(now: date)
            case 2:
                state.playerTwo.updateClockEndFrom(now: date)
            default:
                fatalError()
            }
            state.gameState = .active(playerId: id)
            return .none

        case .outOfTime:
            return Effect.none
        }

    case .settingsButtonTapped:
        return Effect.none

    case .gameStateButtonTapped:
        return Effect.none

    case .pauseGame:
        if case .active(let activePlayerId) = state.gameState {
            state.gameState = .paused(playerId: activePlayerId)
        }

        return Effect.none

    case .resetGame:
        state.playerOne.resetTimeRemaining()
        state.playerTwo.resetTimeRemaining()
        state.gameState = .ready
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
            state.gameState = .outOfTime(playerId: id)
        }
        return .none
    }
}
