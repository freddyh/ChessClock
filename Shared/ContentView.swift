import SwiftUI

struct ContentView: View {
    @State var activePlayer: Int = 1
    @State var players: [Player]
    @State var gameState: Int = 0
    @State var playerOneEndDate: Date?
    @State var playerTwoEndDate: Date?
    let playerOneClockInitial: TimeInterval = 60 * 10
    let playerTwoClockInitial: TimeInterval = 60 * 10
    @State var playerOneTimeRemaining: TimeInterval = 60 * 10
    @State var playerTwoTimeRemaining: TimeInterval = 60 * 10
    @State var lastClockStart: Date? = nil
    @State var secondsElapsed: TimeInterval = 0
    @State var rotation: Angle = .degrees(90)

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            PlayerButton(
                enabled: isPlayerEnabled(player: 1),
                timeRemaining: players[0].timeRemaining
            ) {
                giveControlTo(player: 2, date: Date())
            }

            pauseAndSettingsView

            PlayerButton(
                enabled: isPlayerEnabled(player: 2),
                timeRemaining: players[1].timeRemaining
            ) {
                giveControlTo(player: 1, date: Date())
            }

        }
        .onReceive(timer) { input in
            guard gameState == 1 else {
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

            Button(action: { resetGame() }) {
                Image(systemName: "gobackward")
            }

            Spacer()

            Button(action: { playOrPause(gameState: gameState) }) {
                Image(systemName: gameState == 1 ? "pause" : "play.fill")
            }

            Spacer()

            Button(action: { openSettings() }) {
                Image(systemName: "gear")
            }

            Spacer()
        }
    }

    func isPlayerEnabled(player: Int) -> Bool {
        return activePlayer == player && gameState != 0
    }

    func updateTimeRemaining(for player: Int) {
        var p = currentPlayer(number: player)
        if p.clockEnd == nil {
            p.clockEnd = Date().addingTimeInterval(p.initialTime)
        }
        p.timeRemaining = p.clockEnd!.timeIntervalSince1970 - Date().timeIntervalSince1970
        updatePlayer(number: player, player: p)
    }

    func giveControlTo(player: Int, date: Date) {
        guard activePlayer != player else { return }

        if gameState == 0 { gameState = 1 }

        var p = currentPlayer(number: player)
        p.updateClockEndFrom(now: date)
        updatePlayer(number: player, player: p)

        activePlayer = player
    }

    func resetGame() {
        gameState = 0
        lastClockStart = nil
    }

    func playOrPause(gameState: Int) {
        switch gameState {
        case 0:
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

            self.gameState = 1
        case 1:
            pauseGame()
        default:
            fatalError()
        }
    }

    func currentPlayer(number: Int) -> Player {
        players[number - 1]
    }

    func updatePlayer(number: Int, player: Player) {
        players[number - 1] = player
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
        gameState = 0
    }
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
}

struct PlayerButton: View {
    var enabled: Bool
    var timeRemaining: Double
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Rectangle().fill(enabled ? .green : .gray)
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
        ContentView(players: [
            .init(id: 1, initialTime: 60),
            .init(id: 2, initialTime: 120),
        ])
    }
}
