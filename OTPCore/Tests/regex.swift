import Foundation
import Testing
import SwiftUI

@testable import OTPCore
import RegexBuilder

let flags: [String: Color] = ["abc": .red, "xyz": .orange]

@Test func Regex() async throws {
    let needle = "2025-01-03 01:02:03.12345: 100, abc, 0.01"
    let re = Regex {
        Capture(.iso8601(timeZone: .current, includingFractionalSeconds: true, dateTimeSeparator: .space))
        ": "
        Capture(OneOrMore(.digit))
        ", "
        Capture {
            ChoiceOf {
                "abc"
                "xyz"
            }
        } transform: { ($0.uppercased(), flags[String($0)]!) }
    }
    let match = needle.firstMatch(of: re)
    #expect(Calendar.current.component(.year, from: (match?.1)!) == 2025)
    #expect(match?.2 == "100")
    #expect(match?.3.0 == "ABC")
    #expect(match?.3.1 == .red)
}
