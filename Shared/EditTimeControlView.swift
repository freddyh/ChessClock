import SwiftUI

enum IncrementType {
    case simple
    case bronstein
    case fischer
}

struct PlayerClock {
    let totalTime: TimeInterval
    let incrementAmount: TimeInterval
    let incrementType: IncrementType
}

struct TimeControl {
    let name: String
    let playerOneClock: PlayerClock
    let playerTwoClock: PlayerClock
}


struct EditTimeControlView: View {
    @State var hours: Int = 0
    @State var minutes: Int = 0

    var body: some View {
        HStack {
            Picker("Hours", selection: $hours) {
                ForEach(0..<100) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)

            Picker("Minutes", selection: $minutes) {
                ForEach(0..<100) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
        }
    }
}

struct EditTimeControlView_Previews: PreviewProvider {
    static var previews: some View {
        EditTimeControlView()
    }
}
