import ComposableArchitecture
import SwiftUI

struct ContentViewComposable: View {
    @Environment(\.scenePhase) var scenePhase
    let store: Store<ClockFeature.State, ClockFeature.Action>
    @State var isSettingsPresented: Bool = false
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        WithViewStore(self.store) { viewStore in
            ZStack {
                VStack(spacing: 0) {
                    PlayerButtonView(
                        fill: buttonFillColor(player: 1, gameState: viewStore.gameState),
                        enabled: isPlayerEnabled(gameState: viewStore.gameState, player: 1),
                        timeRemaining: viewStore.playerOne.timeRemaining
                    ) {
                        viewStore.send(.playerClockButtonTapped(2))
                    }
                    .rotationEffect(.degrees(180))

                    Divider()

                    PlayerButtonView(
                        fill: buttonFillColor(player: 2, gameState: viewStore.gameState),
                        enabled: isPlayerEnabled(gameState: viewStore.gameState, player: 2),
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

                    if case .active(_) = viewStore.gameState {
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
                guard case .active(let activePlayer) = viewStore.gameState else {
                    return
                }

                viewStore.send(.playerTimeUpdated(activePlayer))
            }
//            .fullScreenCover(isPresented: $isSettingsPresented) {
//                VStack {
//                    HStack {
//                        Text("1")
//                        Stepper {
//                            Text("minutes")
//                        } onIncrement: {
//                        } onDecrement: {
////                            viewStore.isSettingsPresented = false
//
//                        } onEditingChanged: { isEditing in
//                            print(isEditing)
//                        }
//
//                    }
//
//                    HStack {
//                        Text("1")
//
//                        Stepper {
//                            Text("seconds")
//                        } onIncrement: {
//                        } onDecrement: {
//                        } onEditingChanged: { isEditing in
//                            print(isEditing)
//                        }
//                    }
//                }
//            }
            .onChange(of: scenePhase) { newValue in
                switch newValue {
                case .background, .inactive:
                    viewStore.send(.pauseGame)
                case .active:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    func buttonFillColor(player: Int, gameState: GameState) -> Color {
        switch gameState {
        case .active(let activePlayer):
            return player == activePlayer ? .green : .gray
        case .ready, .paused:
            return .gray
        case .outOfTime:
            return .red
        }
    }

    func isPlayerEnabled(gameState: GameState, player: Int) -> Bool {
        switch gameState {
        case .ready:
            return true
        case .active(let activePlayer):
            return activePlayer == player
        case .paused:
            return true
        case .outOfTime:
            return false
        }
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
                    VStack {
                        if timeRemaining != 0 {
                            Text(
                                DateComponentsFormatter
                                    .remainingTimeFormatter
                                    .string(
                                        for: DateComponents(
                                            hour: Int(timeRemaining / 3600),
                                            minute: Int(timeRemaining / 60) % 60,
                                            second: Int(timeRemaining) % 60
                                        )
                                    ) ?? "\(timeRemaining)")
                            .font(.system(size: 40))
                            .fontWeight(.semibold)
                        }
                        if timeRemaining <= 0 { Text("Out of Time") }
                    }
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
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
}

enum GameState {
    case ready
    case active(playerId: Int)
    case paused(playerId: Int)
    case outOfTime(playerId: Int)
}

extension GameState: Equatable {}

struct Player {
    var id: Int
    private var clockEnd: Date?
    var initialTime: TimeInterval
    var timeRemaining: TimeInterval

    init(id: Int, initialTime: TimeInterval, timeRemaining: TimeInterval? = nil) {
        self.id = id
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

extension Player: Equatable {}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
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
#endif
