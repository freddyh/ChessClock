import SwiftUI

struct ContentView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State var activePlayer: Int?
    @State var gameState: GameState = .ready
    @State var lastClockStart: Date? = nil
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                PlayerButtonView(
                    fill: buttonFillColor(player: 1, gameState: gameState),
                    enabled: isPlayerEnabled(player: 1),
                    timeRemaining: appViewModel.playerOne.timeRemaining
                ) {
                    giveControlTo(player: 2, date: Date())
                }
                .rotationEffect(.degrees(180))

                Divider()

                PlayerButtonView(
                    fill: buttonFillColor(player: 2, gameState: gameState),
                    enabled: isPlayerEnabled(player: 2),
                    timeRemaining: appViewModel.playerTwo.timeRemaining
                ) {
                    giveControlTo(player: 1, date: Date())
                }

            }

            pauseAndSettingsView
        }

        .edgesIgnoringSafeArea(.all)
        .onReceive(timer) { input in
            guard gameState == .active, let activePlayer else {
                return
            }

            updateTimeRemaining(for: activePlayer)
        }
    }

    func buttonFillColor(player: Int, gameState: GameState) -> Color {
        switch gameState {
        case .active:
            return player == activePlayer ? .green : .gray
        case .ready, .paused:
            return .gray
        case .outOfTime:
            return .red
        }
    }

    var pauseAndSettingsView: some View {
        HStack {
            Spacer()

            if gameState != .ready {
                Button(action: resetGame) {
                    Image(systemName: "gobackward")
                }
                Spacer()
            }

            if gameState == .active {
                Button(action: pauseGame) {
                    Image(systemName: "pause")
                }

                Spacer()
            }
            else {
                Button(action: openSettings) {
                    Image(systemName: "gear")
                }

                Spacer()
            }
        }
        .zIndex(100)
    }

    func isPlayerEnabled(player: Int) -> Bool {
        switch gameState {
        case .ready:
            return true
        case .active:
            return activePlayer == player
        case .paused:
            return true
        case .outOfTime:
            return false
        }
    }

    func updateTimeRemaining(for player: Int) {
        appViewModel.updatePlayerTime(id: player, from: Date())
        if appViewModel.isPlayerOutOfTime(id: player) {
            gameState = .outOfTime
        }
    }

    func giveControlTo(player: Int, date: Date) {
        switch gameState {
        case .ready:
            // give control to other player
            gameState = .active
            appViewModel.updateClockEndFrom(id: player, date: date)
            activePlayer = player

        case .active:
            // must be the active player to give control to other player
            guard activePlayer != player else { return }
            if gameState == .paused { gameState = .active }
            appViewModel.updateClockEndFrom(id: player, date: date)
            activePlayer = player

        case .paused:
            // give control to other player
            gameState = .active
            appViewModel.updateClockEndFrom(id: player, date: date)
            activePlayer = player

        case .outOfTime:
            break
        }
    }

    func resetGame() {
        activePlayer = nil
        appViewModel.resetPlayerTimeRemaining(id: 1)
        appViewModel.resetPlayerTimeRemaining(id: 2)
        gameState = .ready
        lastClockStart = nil
    }

    func playOrPause(gameState: GameState) {
        switch gameState {
        case .active:
            pauseGame()
        case .ready, .paused:
            if let activePlayer {
                // Game Initilizer
                if lastClockStart == nil {
                    lastClockStart = Date()
                    appViewModel.updateClockEndFrom(id: activePlayer, date: Date())
                }
                else {
                    unPausePlayer(activePlayer)
                }

                self.gameState = .active
            }
        case .outOfTime:
            break
        }
    }

    func unPausePlayer(_ player: Int) {
        appViewModel.updateClockEndFrom(id: player, date: Date())
    }

    func openSettings() {
//        if gameState == .outOfTime { return }
//        pauseGame()
    }

    func pauseGame() {
        gameState = .paused
    }
}

enum GameState {
    case ready
    case active
    case paused
    case outOfTime
}

struct Player {
    var id: Int
    var clockEnd: Date?
    var initialTime: TimeInterval
    var timeRemaining: TimeInterval

    init(id: Int, clockEnd: Date? = nil, initialTime: TimeInterval, timeRemaining: TimeInterval? = nil) {
        self.id = id
        self.clockEnd = clockEnd
        self.initialTime = initialTime
        self.timeRemaining = timeRemaining ?? initialTime
    }

    mutating func updateClockEndFrom(now: Date) {
        clockEnd = now.addingTimeInterval(timeRemaining)
    }

    mutating func resetTimeRemaining() {
        timeRemaining = initialTime
    }

    mutating func updateTimeRemaining(from now: Date) {
        if clockEnd == nil {
            clockEnd = now.addingTimeInterval(initialTime)
        }
        timeRemaining = clockEnd!.timeIntervalSince1970 - now.timeIntervalSince1970
    }
}

struct PlayerButtonView: View {
    var fill: Color
    var enabled: Bool
    var timeRemaining: Double
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Rectangle().fill(fill)
                .overlay(
                    Text(
                        DateComponentsFormatter
                            .remainingTimeFormatter
                            .string(
                                for: DateComponents(
                                    second: Int(timeRemaining)
                                )
                            ) ?? "\(timeRemaining)")
                    .font(.system(size: 40))
                    .fontWeight(.semibold)
                )
        })
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

extension DateComponentsFormatter {
    static var remainingTimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            appViewModel: AppViewModel.init(
                playerOne: Player.init(id: 1, initialTime: 5),
                playerTwo: Player.init(id: 2, initialTime: 10)
            )
        )
    }
}
