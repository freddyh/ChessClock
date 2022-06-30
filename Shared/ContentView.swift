import ComposableArchitecture
import SwiftUI

struct ContentViewComposable: View {
    let store: Store<AppState, AppAction>
    @State var isSettingsPresented: Bool = false
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        WithViewStore(self.store) { viewStore in
            ZStack {
                VStack(spacing: 0) {
                    PlayerButtonView(
                        fill: buttonFillColor(player: 1, gameState: viewStore.gameState, activePlayer: viewStore.activePlayer),
                        enabled: isPlayerEnabled(gameState: viewStore.gameState, player: 1, activePlayer: viewStore.activePlayer ?? -1),
                        timeRemaining: viewStore.playerOne.timeRemaining
                    ) {
                        viewStore.send(.playerClockButtonTapped(2))
                    }
                    .rotationEffect(.degrees(180))

                    Divider()

                    PlayerButtonView(
                        fill: buttonFillColor(player: 2, gameState: viewStore.gameState, activePlayer: viewStore.activePlayer),
                        enabled: isPlayerEnabled(gameState: viewStore.gameState, player: 2, activePlayer: viewStore.activePlayer ?? -1),
                        timeRemaining: viewStore.playerTwo.timeRemaining
                    ) {
                        viewStore.send(.playerClockButtonTapped(1))
                    }

                }

                HStack {
                    Spacer()

                    if viewStore.gameState != .ready {
                        Button(action: { viewStore.send(.resetGame) }) {
                            Image(systemName: "gobackward")
                        }
                        Spacer()
                    }

                    if viewStore.gameState == .active {
                        Button(action: { viewStore.send(.pauseGame) }) {
                            Image(systemName: "pause")
                        }

                        Spacer()
                    }
                    else {
                        Button(action: { viewStore.send(.settingsButtonTapped) }) {
                            Image(systemName: "gear")
                        }

                        Spacer()
                    }
                }
                .zIndex(100)
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(timer) { input in
                guard viewStore.gameState == .active, let activePlayer = viewStore.activePlayer else {
                    return
                }

                viewStore.send(.playerTimeUpdated(activePlayer))
            }
            .fullScreenCover(isPresented: $isSettingsPresented) {
                VStack {
                    HStack {
                        Text("1")
                        Stepper {
                            Text("minutes")
                        } onIncrement: {
                        } onDecrement: {
//                            viewStore.isSettingsPresented = false

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
    }

    func buttonFillColor(player: Int, gameState: GameState, activePlayer: Int?) -> Color {
        switch gameState {
        case .active:
            return player == activePlayer ? .green : .gray
        case .ready, .paused:
            return .gray
        case .outOfTime:
            return .red
        }
    }

    func isPlayerEnabled(gameState: GameState, player: Int, activePlayer: Int?) -> Bool {
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
}

enum GameState {
    case ready
    case active
    case paused
    case outOfTime
}

extension GameState: Equatable {}

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

extension Player: Equatable {}
