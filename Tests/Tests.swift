import Foundation
import Testing

struct Tests {
    @Test func Base32Encode() async throws {
        #expect(Base32.encode(data: "abc".data(using: .utf8)!) == "MFRGG")
    }

    @Test func JSONEncode() async throws {
        let data = try JSONDecoder().decode([String: Int].self, from: Data(#"{"a": 1}"#.utf8))
        #expect(data == ["a": 1])
    }
}
