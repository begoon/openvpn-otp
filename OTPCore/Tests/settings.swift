import Foundation
import Testing

@testable import OTPCore

@Test func JSONEncode() async throws {
    let data = try JSONDecoder().decode([String: Int].self, from: Data(#"{"a": 1}"#.utf8))
    #expect(data == ["a": 1])
}

@Test func SettingsDefaults() async throws {
    let settings = Settings(from: URL(fileURLWithPath: "abc"))
    #expect(!settings.ok)
}

@Test func SettingsBadJSON() async throws {
    let settings = Settings(from: "abc")
    #expect(!settings.ok)
    #expect(settings.error != nil)
    let error = settings.error!
    #expect(error.contains("DecodingError"))
    #expect(error.contains("The given data was not valid JSON."))
    #expect(error.contains("Unexpected character 'a' around line 1, column 1."))
}

@Test func SettingsEmptyJSON() async throws {
    let settings = Settings(from: "{}")
    #expect(!settings.ok)
    #expect(settings.error != nil)
    let error = settings.error!
    #expect(error.contains("DecodingError"))
    #expect(error.contains(#"keyNotFound(CodingKeys(stringValue: "account", intValue: nil)"#))
}
