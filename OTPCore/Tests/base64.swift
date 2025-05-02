import Foundation
import Testing

@testable import OTPCore

@Test func Base32Encode() async throws {
    #expect(Base32.encode(data: String("abc").data(using: .utf8)!) == "MFRGG")
}

@Test func Base32Decode() async throws {
    #expect(
        throws: DecodingError.keyNotFound, []),
        String(data: Base32.decode(string: ""), encoding: .utf8)
    )
    #expect(try String(data: Base32.decode(string: "MFRGG"), encoding: .utf8) == "abc")
}
