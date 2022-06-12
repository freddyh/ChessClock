import SwiftUI

struct ContentView: View {
    @State var activePlayer: Int = 1
    @State var gameState: Int = 0
    @State var playerOneClockInitial: TimeInterval = 60 * 10
    @State var playerTwoClockInitial: TimeInterval = 60 * 10
    @State var playerOneTimeRemaining: TimeInterval = 60 * 10
    @State var playerTwoTimeRemaining: TimeInterval = 60 * 10
    @State var lastClockStart: Date? = nil
    @State var secondsElapsed: TimeInterval = 0

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            PlayerButton(isActive: activePlayer == 1 && gameState != 0, timeRemaining: playerOneTimeRemaining) {
                if activePlayer == 1 {
                    activePlayer = 2
                    lastClockStart = Date()
                }
            }
            #if RELEASE
            .rotationEffect(.degrees(180))
            #endif


            HStack(spacing: 100) {
                Button(
                    action: {
                        gameState = 0
                    }
                ) {
                    Image(systemName: "pause")
                }

                Button(
                    action: {
                        gameState = 0

                    }
                ) {
                    Image(systemName: "gobackward")
                }

                Button(
                    action: {
                        gameState = 1
                        lastClockStart = Date()

                    }
                ) {
                    Image(systemName: gameState == 1 ? "play" : "play.fill")
                }
            }

            PlayerButton(isActive: activePlayer == 2 && gameState != 0, timeRemaining: playerTwoTimeRemaining) {
                if activePlayer == 2 {
                    activePlayer = 1
                    lastClockStart = Date()
                }
            }
        }
        .onReceive(timer) { input in
            guard gameState == 1, let lastClockStartDate = lastClockStart else {
                return
            }
            let secondsElapsed = Date().timeIntervalSince1970 - lastClockStartDate.timeIntervalSince1970

            switch activePlayer {
            case 1:
                playerOneTimeRemaining = playerOneClockInitial - secondsElapsed
            case 2:
                playerTwoTimeRemaining = playerTwoClockInitial - secondsElapsed
            default:
                fatalError()
            }
        }
    }
}

struct PlayerButton: View {
    var isActive: Bool
    var timeRemaining: Double
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Rectangle().fill(isActive ? .green : .gray)
                .overlay(
                    Text("\(timeRemaining / 60.0)")
                        .font(.system(size: 40))
                        .fontWeight(.semibold)
                )
        })
        .buttonStyle(.plain)
        .disabled(!isActive)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
