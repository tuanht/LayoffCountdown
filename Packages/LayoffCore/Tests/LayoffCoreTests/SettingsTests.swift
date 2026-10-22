import XCTest
@testable import LayoffCore

final class SettingsTests: XCTestCase {
    // Fixed names: cfprefsd keeps an empty plist per suite name, so per-test UUID suites pile up.
    private static let suiteName = "test.LayoffCore.settings"
    private static let sourceSuiteName = "test.LayoffCore.migrationSource"

    private func makeDefaults() -> UserDefaults { UserDefaults(suiteName: Self.suiteName)! }
    private func makeSourceDefaults() -> UserDefaults { UserDefaults(suiteName: Self.sourceSuiteName)! }

    private func clearSuites() {
        for name in [Self.suiteName, Self.sourceSuiteName] {
            UserDefaults().removePersistentDomain(forName: name)
        }
    }

    override func setUp() {
        super.setUp()
        clearSuites()
    }

    override func tearDown() {
        clearSuites()
        super.tearDown()
    }

    private func storeJSON(_ json: String, in defaults: UserDefaults) {
        defaults.set(Data(json.utf8), forKey: "layoffSettings.v1")
    }

    func testRoundTrip() {
        let store = SettingsStore(defaults: makeDefaults())
        let settings = LayoffSettings(
            layoffDate: Date(timeIntervalSinceReferenceDate: 800_000_000),
            startDate: Date(timeIntervalSinceReferenceDate: 790_000_000),
            emoji: "🪦",
            menuBarStyle: .full
        )
        store.save(settings)
        XCTAssertEqual(store.load(), settings)
    }

    func testEmptyStoreLoadsDefaults() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).load(), .default)
    }

    func testCorruptDataLoadsDefaults() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        defaults.set(Data("not json".utf8), forKey: "layoffSettings.v1")
        XCTAssertEqual(store.load(), .default)
    }

    func testMissingKeysDecodeToDefaults() {
        let defaults = makeDefaults()
        storeJSON(#"{"layoffDate": 800000000}"#, in: defaults)
        let loaded = SettingsStore(defaults: defaults).load()
        XCTAssertEqual(loaded.layoffDate, Date(timeIntervalSinceReferenceDate: 800_000_000))
        XCTAssertNil(loaded.startDate)
        XCTAssertEqual(loaded.emoji, "💀")
        XCTAssertEqual(loaded.menuBarStyle, .short)
    }

    func testUnknownStyleKeepsDate() {
        let defaults = makeDefaults()
        storeJSON(#"{"layoffDate": 800000000, "emoji": "🪦", "menuBarStyle": "bogus"}"#, in: defaults)
        let loaded = SettingsStore(defaults: defaults).load()
        XCTAssertEqual(loaded.layoffDate, Date(timeIntervalSinceReferenceDate: 800_000_000))
        XCTAssertEqual(loaded.emoji, "🪦")
        XCTAssertEqual(loaded.menuBarStyle, .short)
    }

    func testWrongTypeEmojiKeepsDate() {
        let defaults = makeDefaults()
        storeJSON(#"{"layoffDate": 800000000, "emoji": 42, "menuBarStyle": "full"}"#, in: defaults)
        let loaded = SettingsStore(defaults: defaults).load()
        XCTAssertEqual(loaded.layoffDate, Date(timeIntervalSinceReferenceDate: 800_000_000))
        XCTAssertEqual(loaded.emoji, "💀")
        XCTAssertEqual(loaded.menuBarStyle, .full)
    }

    func testEmojiSanitizing() {
        XCTAssertEqual(LayoffSettings.sanitizedEmoji(""), "💀")
        XCTAssertEqual(LayoffSettings.sanitizedEmoji("   "), "💀")
        XCTAssertEqual(LayoffSettings.sanitizedEmoji("🪦 RIP"), "🪦")
        XCTAssertEqual(LayoffSettings.sanitizedEmoji(" 🔥"), "🔥")
        XCTAssertEqual(LayoffSettings.sanitizedEmoji("👨‍👩‍👧"), "👨‍👩‍👧")   // ZWJ sequence is one grapheme
    }

    func testFirstSaveSetsStartDate() {
        let now = Date(timeIntervalSinceReferenceDate: 790_000_000)
        let layoff = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let updated = LayoffSettings.default.settingLayoffDate(layoff, now: now)
        XCTAssertEqual(updated.layoffDate, layoff)
        XCTAssertEqual(updated.startDate, now)
    }

    func testLaterSaveKeepsStartDate() {
        let start = Date(timeIntervalSinceReferenceDate: 780_000_000)
        var settings = LayoffSettings.default
        settings.startDate = start
        let layoff = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let updated = settings.settingLayoffDate(layoff, now: Date(timeIntervalSinceReferenceDate: 790_000_000))
        XCTAssertEqual(updated.layoffDate, layoff)
        XCTAssertEqual(updated.startDate, start)
    }

    func testDefaultLayoffDateIs1700Local() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 9, minute: 30))!
        let result = LayoffSettings.defaultLayoffDate(now: now, calendar: calendar)
        let parts = calendar.dateComponents([.hour, .minute, .second], from: result)
        XCTAssertEqual(parts.hour, 17)
        XCTAssertEqual(parts.minute, 0)
        XCTAssertEqual(parts.second, 0)
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: result)).day
        XCTAssertEqual(days, 30)
    }

    func testMigratesFromStandardWhenGroupEmpty() {
        let standard = makeSourceDefaults()
        let standardSettings = LayoffSettings.default.settingLayoffDate(
            Date(timeIntervalSinceReferenceDate: 800_000_000),
            now: Date(timeIntervalSinceReferenceDate: 790_000_000)
        )
        SettingsStore(defaults: standard).save(standardSettings)

        let group = makeDefaults()
        XCTAssertEqual(SettingsStore(defaults: group, migratingFrom: standard).load(), standardSettings)

        var groupSettings = LayoffSettings.default
        groupSettings.emoji = "🔥"
        SettingsStore(defaults: group).save(groupSettings)
        XCTAssertEqual(SettingsStore(defaults: group, migratingFrom: standard).load(), groupSettings)
    }

    func testNoAppGroupFallsBackToStandard() {
        // Only nil case: on macOS `containerURL(forSecurityApplicationGroupIdentifier:)` returns URL even for fake group.
        XCTAssertFalse(SettingsStore.make(appGroupID: nil).usesAppGroup)
    }
}
