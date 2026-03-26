import XCTest
@testable import OpenOatsKit

final class OpenOatsDeepLinkTests: XCTestCase {
    func testParseNotesDeepLinkAcceptsSafeSessionID() {
        let url = URL(string: "openoats://notes?sessionID=session_2026-03-26_10-00-00")!
        let command = OpenOatsDeepLink.parse(url)
        XCTAssertEqual(command, .openNotes(sessionID: "session_2026-03-26_10-00-00"))
    }

    func testParseNotesDeepLinkDropsUnsafeSessionID() {
        let url = URL(string: "openoats://notes?sessionID=../../etc/passwd")!
        let command = OpenOatsDeepLink.parse(url)
        XCTAssertEqual(command, .openNotes(sessionID: nil))
    }

    func testParseNotesDeepLinkAcceptsExtraBrainScheme() {
        let url = URL(string: "extrabrain://notes?sessionID=session_2026-03-26_10-00-00")!
        let command = OpenOatsDeepLink.parse(url)
        XCTAssertEqual(command, .openNotes(sessionID: "session_2026-03-26_10-00-00"))
    }
}
