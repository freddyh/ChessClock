//
//  ChessClockApp.swift
//  Shared
//
//  Created by Freddy Hernandez Jr on 6/11/22.
//

import ComposableArchitecture
import Dependencies
import SwiftUI

@main
struct ChessClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentViewComposable(
                store: Store(
                    initialState: ClockFeature.State(
                        playerOne: Player(id: 1, initialTime: 10),
                        playerTwo: Player(id: 2, initialTime: 10),
                        gameState: .ready
                    ),
                    reducer: ClockFeature()
                )
            )
        }
    }
}

struct ClockFeature: ReducerProtocol {
    struct State: Equatable {
        var playerOne: Player
        var playerTwo: Player
        var gameState: GameState = .ready
        var showSettings: Bool = false
    }

    enum Action: Equatable {
        case playerClockButtonTapped(Int)
        case settingsButtonTapped
        case dimissSettingsButtonTapped
        case gameStateButtonTapped
        case pauseGame
        case resetGame
        case playerTimeUpdated(Int)
    }

    @Dependency(\.date) var date

    func reduce(into state: inout State, action: Action) -> ComposableArchitecture.EffectTask<Action> {
        switch action {
        case .playerClockButtonTapped(let id):
            switch state.gameState {
            case .ready:
                // give control to other player
                let now = date.now
                switch id {
                case 1:
                    state.playerOne.updateClockEndFrom(now: now)
                case 2:
                    state.playerTwo.updateClockEndFrom(now: now)
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

                let date = date.now
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
                let date = date.now
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
            state.showSettings.toggle()
            return Effect.none

        case .dimissSettingsButtonTapped:
            state.showSettings = false
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
            let now = date.now
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
}
