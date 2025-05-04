import Foundation
import Testing

@testable import OTPCore

@Test func Base32Encode() async throws {
    #expect(Base32.encode(data: String("abc").data(using: .utf8)!) == "MFRGG")
    #expect(Base32.encode(data: String("").data(using: .utf8)!) == "")
}

@Test func Base32Decode() async throws {
    #expect(try String(data: Base32.decode(string: ""), encoding: .utf8) == "")
    #expect(try String(data: Base32.decode(string: "MFRGG"), encoding: .utf8) == "abc")
    #expect(throws: Base32Error.invalidBase32String) { try Base32.decode(string: ".") }
}
