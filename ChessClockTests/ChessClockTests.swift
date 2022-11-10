import ComposableArchitecture
import XCTest

@testable import ChessClock

@MainActor
final class ChessClockTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() async throws {
        let store = TestStore(
            initialState: ClockFeature.State(
                playerOne: .init(id: 1, initialTime: 5),
                playerTwo: .init(id: 2, initialTime: 5)),
            reducer: ClockFeature()
        )

        XCTAssertEqual(store.state.gameState, .ready)
    }
}
