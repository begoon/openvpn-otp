import Foundation
import Testing
import SwiftUI

@testable import OTPCore

@Test func testWithPlainText() {
    #expect(colored("abc").1 == nil)
}

@Test func testWithKnownColor() {
    #expect(colored("@red:abc 123").1 == .red)
}

@Test func testWithUnknownColor() {
    #expect(colored("@blurple:abc 123").1 == nil)
}

@Test func testEmpty() {
    #expect(colored("").1 == nil)
}
