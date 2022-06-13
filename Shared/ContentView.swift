import SwiftUI

struct ContentView: View {
    @State var activePlayer: Int = 1
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
                timeRemaining: playerOneTimeRemaining
            ) {
                giveControlTo(player: 2, date: Date())
            }
            #if RELEASE
            .rotationEffect(.degrees(90))
            #endif

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

            PlayerButton(
                enabled: isPlayerEnabled(player: 2),
                timeRemaining: playerTwoTimeRemaining
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

    func isPlayerEnabled(player: Int) -> Bool {
        return activePlayer == player && gameState != 0
    }

    func updateTimeRemaining(for player: Int) {
        switch player {
        case 1:
            playerOneTimeRemaining =  playerOneEndDate!.timeIntervalSince1970 - Date().timeIntervalSince1970
        case 2:
            playerTwoTimeRemaining = playerTwoEndDate!.timeIntervalSince1970 - Date().timeIntervalSince1970
        default:
            fatalError()
        }
    }

    func giveControlTo(player: Int, date: Date) {
        guard activePlayer != player else { return }

        switch activePlayer {
        case 1:
            playerTwoEndDate = date.addingTimeInterval(playerTwoTimeRemaining)
        case 2:
            playerOneEndDate = date.addingTimeInterval(playerOneTimeRemaining)
        default:
            break
        }

        self.activePlayer = player
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
                playerOneEndDate = Date().addingTimeInterval(playerOneClockInitial)
                playerTwoEndDate = Date().addingTimeInterval(playerTwoClockInitial)
            }
            else {
                unPausePlayer(activePlayer)
            }


            self.gameState = 1
        case 1:
            self.gameState = 0
        default:
            fatalError()
        }
    }

    func unPausePlayer(_ player: Int) {
        switch player {
        case 1:
            playerOneEndDate = Date().addingTimeInterval(playerOneTimeRemaining)
        case 2:
            playerTwoEndDate = Date().addingTimeInterval(playerTwoTimeRemaining)
        default:
            break
        }
    }

    func openSettings() {

    }
}

struct Player {
    var id: Int
    var clockEnd: Date?
    var initialTime: TimeInterval
    var timeRemaining: TimeInterval
}

struct PlayerButton: View {
    var enabled: Bool
    var timeRemaining: Double
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Rectangle().fill(enabled ? .green : .gray)
                .overlay(
                    Text("\(timeRemaining / 60.0)")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension NumberFormatter {
//    static var shared: [String: NumberFormatter]
}

// Device Orientation Subscriber

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
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
