import SwiftUI

struct ContentView: View {
    @State var activePlayer: Int = 1
    @State var gameState: Int = 0
    @State var playerOneTime: String = "10:25"
    @State var playerTwoTime: String = "10:20"

    var body: some View {
        VStack {
            PlayerButton(isActive: activePlayer == 1 && gameState != 0, time: playerOneTime) {
                if activePlayer == 1 {
                    activePlayer = 2
                }
            }
            .rotationEffect(.degrees(180))

            HStack(spacing: 100) {
                Button.init(action: { gameState = 0 }) {
                    Image(systemName: "stop")
                }
                Button.init(action: { gameState = 1 }) {
                    Image(systemName: "play")
                }

            }

            PlayerButton(isActive: activePlayer == 2 && gameState != 0, time: playerTwoTime) {
                if activePlayer == 2 {
                    activePlayer = 1
                }
            }
        }
    }
}

struct PlayerButton: View {
    var isActive: Bool
    var time: String
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Rectangle().fill(isActive ? .green : .gray)
                .overlay(
                    Text(time)
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
