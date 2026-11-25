import XCTest
@testable import MahjTrainer

@MainActor
final class ClassCodeTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "ClassCodeTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func testNormalizesWhatPlayersType() {
        XCTAssertEqual(ClassCode.normalized(" okl-ets "), "OKLETS")
        XCTAssertEqual(ClassCode.normalized("ab 12"), "AB12")
        XCTAssertNil(ClassCode.normalized("abc"))
        XCTAssertNil(ClassCode.normalized("ABCDEFGHIJKLM"))
        XCTAssertNil(ClassCode.normalized("ÉÉÉÉ"))
    }

    func testReadsTheCardLink() {
        XCTAssertEqual(ClassCode.code(from: URL(string: "mahj://class/okLets")!), "OKLETS")
        XCTAssertEqual(ClassCode.code(from: URL(string: "mahj://class?code=OKLETS")!), "OKLETS")
        XCTAssertNil(ClassCode.code(from: URL(string: "mahj://challenge")!))
        XCTAssertNil(ClassCode.code(from: URL(string: "https://class/OKLETS")!))
        // A class link is not a screen to open.
        XCTAssertNil(AppDestination(url: URL(string: "mahj://class/OKLETS")!))
    }

    func testJoinKeepsTheClassAcrossLaunches() async {
        let service = ClassCodeService(defaults: defaults) { _, _ in .found(name: "OK Let's Mahjong", focusRoomID: "charleston-room") }
        let outcome = await service.join("oklets")
        XCTAssertEqual(outcome, .joined)
        XCTAssertEqual(service.current?.code, "OKLETS")
        XCTAssertEqual(service.current?.focusRoom?.id, "charleston-room")

        let relaunched = ClassCodeService(defaults: defaults) { _, _ in .offline }
        XCTAssertEqual(relaunched.current?.name, "OK Let's Mahjong")
    }

    func testUnknownCodeAndOfflineJoinNothing() async {
        let missing = ClassCodeService(defaults: defaults) { _, _ in .notFound }
        let notFound = await missing.join("NOPE1")
        XCTAssertEqual(notFound, .notFound)
        XCTAssertNil(missing.current)
        let offline = ClassCodeService(defaults: defaults) { _, _ in .offline }
        let unreachable = await offline.join("OKLETS")
        XCTAssertEqual(unreachable, .offline)
        XCTAssertNil(offline.current)
    }

    func testRefreshPicksUpANewFocusAndDropsAClosedClass() async {
        let focus = FocusBox("charleston-room")
        let service = ClassCodeService(defaults: defaults) { _, _ in
            await focus.value.map { .found(name: "OK Let's Mahjong", focusRoomID: $0) } ?? .notFound
        }
        _ = await service.join("OKLETS")

        await focus.set("table-room")
        await service.refresh(force: true)
        XCTAssertEqual(service.current?.focusRoomID, "table-room")

        await focus.set(nil)
        await service.refresh(force: true)
        XCTAssertNil(service.current)
        XCTAssertNil(ClassCodeService(defaults: defaults) { _, _ in .offline }.current)
    }

    func testOfflineRefreshKeepsTheClass() async {
        let online = ClassCodeService(defaults: defaults) { _, _ in .found(name: "A", focusRoomID: "card-room") }
        _ = await online.join("OKLETS")
        let service = ClassCodeService(defaults: defaults) { _, _ in .offline }
        await service.refresh(force: true)
        XCTAssertEqual(service.current?.code, "OKLETS")
    }

    func testUnknownRoomShowsNoFocus() {
        XCTAssertNil(TeacherClass(code: "OKLETS", name: "A", focusRoomID: "future-room").focusRoom)
    }

    func testLeaveForgetsTheClass() async {
        let service = ClassCodeService(defaults: defaults) { _, _ in .found(name: "A", focusRoomID: "card-room") }
        _ = await service.join("OKLETS")
        service.leave()
        XCTAssertNil(service.current)
        XCTAssertNil(ClassCodeService(defaults: defaults) { _, _ in .offline }.current)
    }

    /// Every room the server's check constraint allows exists in this build.
    func testServerRoomListMatchesTheLibrary() {
        let allowed = ["tile-room", "card-room", "charleston-room", "table-room", "pro-tables"]
        XCTAssertEqual(Set(allowed), Set(DrillLibrary.rooms.map(\.id)))
    }
}

private actor FocusBox {
    var value: String?
    init(_ value: String?) { self.value = value }
    func set(_ new: String?) { value = new }
}
