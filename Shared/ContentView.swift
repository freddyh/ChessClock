import SwiftUI

struct ContentView: View {
    @State var activePlayer: Int?
    @State var playerOne: Player
    @State var playerTwo: Player
    @State var gameState: GameState = .ready
    @State var lastClockStart: Date? = nil
    @State var rotation: Angle = .degrees(90)

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    func buttonFillColor(player: Int, gameState: GameState) -> Color {
        guard gameState != .outOfTime else { return .red }
        guard player == activePlayer else { return .gray }
        return .green
    }

    var body: some View {
        VStack {
            PlayerButtonView(
                fill: buttonFillColor(player: 1, gameState: gameState),
                enabled: isPlayerEnabled(player: 1),
                timeRemaining: playerOne.timeRemaining
            ) {
                giveControlTo(player: 2, date: Date())
            }

            pauseAndSettingsView

            PlayerButtonView(
                fill: buttonFillColor(player: 2, gameState: gameState),
                enabled: isPlayerEnabled(player: 2),
                timeRemaining: playerTwo.timeRemaining
            ) {
                giveControlTo(player: 1, date: Date())
            }

        }
        .onReceive(timer) { input in
            guard gameState == .active, let activePlayer else {
                return
            }

            updateTimeRemaining(for: activePlayer)
        }
        .onRotate { newOrientation in
            switch newOrientation {
            case .portraitUpsideDown:
                rotation = .degrees(-90)
            case .portrait:
                rotation = .degrees(90)
            default:
                break
            }
        }
    }

    var pauseAndSettingsView: some View {
        HStack {
            Spacer()

            if gameState != .ready {
                Button(action: { resetGame() }) {
                    Image(systemName: "gobackward")
                }
                Spacer()
            }

//            Button(action: { playOrPause(gameState: gameState) }) {
//                Image(systemName: gameState == .active ? "pause" : "play.fill")
//            }
//
//            Spacer()

            Button(action: { openSettings() }) {
                Image(systemName: "gear")
            }

            Spacer()
        }
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
        var p = currentPlayer(number: player)
        if p.clockEnd == nil {
            p.clockEnd = Date().addingTimeInterval(p.initialTime)
        }
        p.timeRemaining = p.clockEnd!.timeIntervalSince1970 - Date().timeIntervalSince1970
        updatePlayer(number: player, player: p)
        if p.timeRemaining < 0 {
            gameState = .outOfTime
        }
    }

    func giveControlTo(player: Int, date: Date) {
        switch gameState {
        case .ready:
            // give control to other player
            gameState = .active
            var p = currentPlayer(number: player)
            p.updateClockEndFrom(now: date)
            updatePlayer(number: player, player: p)

            activePlayer = player

        case .active:
            // must be the active player to give control to other player

            guard activePlayer != player else { return }

            if gameState == .paused { gameState = .active }

            var p = currentPlayer(number: player)
            p.updateClockEndFrom(now: date)
            updatePlayer(number: player, player: p)

            activePlayer = player

        case .paused:
            // give control to other player
            gameState = .active
            var p = currentPlayer(number: player)
            p.updateClockEndFrom(now: date)
            updatePlayer(number: player, player: p)

            activePlayer = player

        case .outOfTime:
            break
        }
    }

    func resetGame() {
        activePlayer = nil
        var p1 = currentPlayer(number: 1)
        var p2 = currentPlayer(number: 2)
        p1.resetTimeRemaining()
        p2.resetTimeRemaining()
        updatePlayer(number: 1, player: p1)
        updatePlayer(number: 2, player: p2)
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

                    var p = currentPlayer(number: activePlayer)
                    p.updateClockEndFrom(now: Date())
                    updatePlayer(number: activePlayer, player: p)
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

    func currentPlayer(number: Int) -> Player {
        switch number {
        case 1:
            return playerOne
        case 2:
            return playerTwo
        default:
            fatalError()
        }
    }

    func updatePlayer(number: Int, player: Player) {
        switch number {
        case 1:
            playerOne = player
        case 2:
            playerTwo = player
        default:
            fatalError()
        }
    }

    func unPausePlayer(_ player: Int) {
        var p = currentPlayer(number: player)
        p.updateClockEndFrom(now: Date())
        updatePlayer(number: player, player: p)
    }

    func openSettings() {
        pauseGame()
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
                    #if RELEASE
                        .rotationEffect(.degrees(90))
                    #endif

                )
        })
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// Device Orientation Subscriber
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
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
            playerOne: Player(id: 1, initialTime: 10),
            playerTwo: Player(id: 2, initialTime: 20)
        )
    }
}
