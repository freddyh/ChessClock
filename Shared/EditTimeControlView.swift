import SwiftUI

struct EditTimeControlView: View {
    @State var hours: Int = 0
    @State var minutes: Int = 10
    @State var delaySeconds: Int = 0

    var body: some View {
        List {
            Picker("Hours", selection: $hours) {
                ForEach(0..<100) { Text("\($0)") }
            }

            Picker("Minutes", selection: $minutes) {
                ForEach(0..<100) { Text("\($0)") }
            }

            Picker("Delay", selection: $delaySeconds) {
                ForEach(0..<100) { Text("\($0)") }
            }
        }
    }
}

struct EditTimeControlView_Previews: PreviewProvider {
    static var previews: some View {
        EditTimeControlView()
    }
}
