import SwiftUI

struct ContentView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State var isSettingsPresented: Bool = false
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                PlayerButtonView(
                    fill: buttonFillColor(player: 1, gameState: appViewModel.gameState),
                    enabled: isPlayerEnabled(player: 1),
                    timeRemaining: appViewModel.playerOne.timeRemaining
                ) {
                    giveControlTo(player: 2, date: Date())
                }
                .rotationEffect(.degrees(180))

                Divider()

                PlayerButtonView(
                    fill: buttonFillColor(player: 2, gameState: appViewModel.gameState),
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
            guard appViewModel.gameState == .active, let activePlayer = appViewModel.activePlayer else {
                return
            }

            updateTimeRemaining(for: activePlayer)
        }
        .fullScreenCover(isPresented: $isSettingsPresented) {
            VStack {
                HStack {
                    Text("1")
                    Stepper {
                        Text("minutes")
                    } onIncrement: {
                    } onDecrement: {
                        isSettingsPresented = false

                    } onEditingChanged: { isEditing in
                        print(isEditing)
                    }

                }

                HStack {
                    Text("1")

                    Stepper {
                        Text("seconds")
                    } onIncrement: {
                    } onDecrement: {
                    } onEditingChanged: { isEditing in
                        print(isEditing)
                    }
                }
            }
        }
    }

    func buttonFillColor(player: Int, gameState: GameState) -> Color {
        switch gameState {
        case .active:
            return player == appViewModel.activePlayer ? .green : .gray
        case .ready, .paused:
            return .gray
        case .outOfTime:
            return .red
        }
    }

    var pauseAndSettingsView: some View {
        HStack {
            Spacer()

            if appViewModel.gameState != .ready {
                Button(action: resetGame) {
                    Image(systemName: "gobackward")
                }
                Spacer()
            }

            if appViewModel.gameState == .active {
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
        switch appViewModel.gameState {
        case .ready:
            return true
        case .active:
            return appViewModel.activePlayer == player
        case .paused:
            return true
        case .outOfTime:
            return false
        }
    }

    func updateTimeRemaining(for player: Int) {
        appViewModel.updatePlayerTime(id: player, from: Date())
    }

    func giveControlTo(player: Int, date: Date) {
        switch appViewModel.gameState {
        case .ready:
            // give control to other player
            appViewModel.gameState = .active
            appViewModel.updateClockEndFrom(id: player, date: date)
            appViewModel.activePlayer = player

        case .active:
            // must be the active player to give control to other player
            guard appViewModel.activePlayer != player else { return }
            if appViewModel.gameState == .paused { appViewModel.gameState = .active }
            appViewModel.updateClockEndFrom(id: player, date: date)
            appViewModel.activePlayer = player

        case .paused:
            // give control to other player
            appViewModel.gameState = .active
            appViewModel.updateClockEndFrom(id: player, date: date)
            appViewModel.activePlayer = player

        case .outOfTime:
            break
        }
    }

    func resetGame() {
        appViewModel.activePlayer = nil
        appViewModel.resetPlayerTimeRemaining(id: 1)
        appViewModel.resetPlayerTimeRemaining(id: 2)
        appViewModel.gameState = .ready
        appViewModel.lastClockStart = nil
    }

    func playOrPause(gameState: GameState) {
        switch gameState {
        case .active:
            pauseGame()
        case .ready, .paused:
            if let activePlayer = appViewModel.activePlayer {
                // Game Initilizer
                if appViewModel.lastClockStart == nil {
                    startGame(withPlayer: activePlayer)
                }
                else {
                    unPausePlayer(activePlayer)
                }

                self.appViewModel.gameState = .active
            }
        case .outOfTime:
            break
        }
    }

    func startGame(withPlayer id: Int) {
        appViewModel.lastClockStart = Date()
        appViewModel.updateClockEndFrom(id: id, date: Date())
    }

    func unPausePlayer(_ player: Int) {
        appViewModel.updateClockEndFrom(id: player, date: Date())
    }

    func openSettings() {
        pauseGame()
        isSettingsPresented = true
    }

    func pauseGame() {
        appViewModel.gameState = .paused
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
